package com.example.pivote_studio.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.Format
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.DefaultRenderersFactory
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.data.StreamFormat
import com.example.pivote_studio.drm.PivoteDrmManager

/**
 * Motor central de reproducción basado en Media3 ExoPlayer.
 *
 * Garantías de diseño:
 *   • UNA sola instancia de ExoPlayer por PlatformView, creada en el constructor
 *     (la vista se vincula siempre a un player existente → nunca "audio sin video").
 *   • Cada `prepare()` abre una nueva sesión (sessionId). Los eventos llevan el id
 *     de sesión para que Flutter descarte eventos de canales/servidores anteriores.
 *
 * Recuperación automática (antes de notificar un error fatal a Flutter):
 *   • BehindLiveWindow           → salto al borde en vivo y re-prepare
 *   • Errores de red transitorios → reintento con backoff (1s, 2s, 4s)
 *   • Formato desconocido         → detección por prueba HLS → progresivo → DASH
 *   • Widevine L1 fallando        → reintento automático forzando L3
 *   • Decodificador fallando      → fallback de decoder + un reintento
 *   • Stall prolongado            → re-prepare desde el borde en vivo
 */
@OptIn(UnstableApi::class)
class NativeMediaPlayer(context: Context) {

    companion object {
        private const val TAG = "PivoteExoPlayer"
        private const val MAX_NETWORK_RETRIES = 3
        private const val BASE_RETRY_MS       = 1_000L
        private const val POSITION_TICK_MS    = 500L
        private const val STALL_TIMEOUT_MS    = 20_000L
    }

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Callback de eventos hacia la capa Flutter (siempre en hilo principal). */
    var eventListener: ((Map<String, Any?>) -> Unit)? = null

    /**
     * true si la vista usa TextureView: una TextureView no puede mostrar salida de un
     * decodificador seguro, así que Widevine se fuerza a L3 para evitar pantalla negra.
     */
    var usesTextureSurface: Boolean = false

    // ── Core ─────────────────────────────────────────────────────────────────
    private val trackSelector = DefaultTrackSelector(appContext).apply {
        parameters = buildUponParameters()
            .setAllowVideoMixedMimeTypeAdaptiveness(true)
            .setAllowVideoNonSeamlessAdaptiveness(true)
            .setAllowAudioMixedMimeTypeAdaptiveness(true)
            .setExceedVideoConstraintsIfNecessary(true)
            .setExceedAudioConstraintsIfNecessary(true)
            .setExceedRendererCapabilitiesIfNecessary(true)
            .setTunnelingEnabled(false)
            .setPreferredAudioLanguages("es", "spa", "es-419", "en")
            .setPreferredTextLanguages("es", "spa")
            .setSelectUndeterminedTextLanguage(false)
            .build()
    }

    val player: ExoPlayer = buildPlayer()

    // ── Estado de sesión ────────────────────────────────────────────────────
    private var currentChannel: StreamChannel? = null
    private var sessionId = 0
    private var formatCandidates: List<StreamFormat> = emptyList()
    private var formatIndex = 0
    private var forceL3 = false
    private var networkRetries = 0
    private var decoderRetried = false
    private var hasBeenReady = false
    private var firstFrameRendered = false
    private var bufferingSince = 0L
    private var isReleased = false

    private val currentFormat: StreamFormat
        get() = formatCandidates.getOrElse(formatIndex) { StreamFormat.PROGRESSIVE }

    // ── Scheduler ────────────────────────────────────────────────────────────
    private val retryRunnable = Runnable { recoverInPlace() }

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (isReleased) return
            emit(
                "position",
                "positionMs" to player.currentPosition.coerceAtLeast(0L),
                "bufferedMs" to player.bufferedPosition.coerceAtLeast(0L),
                "durationMs" to durationMs
            )
            checkStall()
            mainHandler.postDelayed(this, POSITION_TICK_MS)
        }
    }

    // ── Propiedades públicas ────────────────────────────────────────────────
    val isPlaying: Boolean get() = player.isPlaying
    val isLive: Boolean get() = player.isCurrentMediaItemLive || player.isCurrentMediaItemDynamic
    val durationMs: Long get() {
        val d = player.duration
        return if (d == C.TIME_UNSET || isLive) -1L else d
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Construcción
    // ─────────────────────────────────────────────────────────────────────────

    private fun buildPlayer(): ExoPlayer {
        val renderers = DefaultRenderersFactory(appContext)
            // Si el decoder primario falla (muy común en Android TV / chipsets baratos)
            // se prueba automáticamente el siguiente decoder disponible.
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)

        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs */                     15_000,
                /* maxBufferMs */                     50_000,
                /* bufferForPlaybackMs */              1_500,
                /* bufferForPlaybackAfterRebufferMs */ 3_000
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(15_000, true)
            .build()

        val audioAttributes = AudioAttributes.Builder()
            .setUsage(C.USAGE_MEDIA)
            .setContentType(C.AUDIO_CONTENT_TYPE_MOVIE)
            .build()

        return ExoPlayer.Builder(appContext, renderers)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .setAudioAttributes(audioAttributes, /* handleAudioFocus = */ true)
            .setHandleAudioBecomingNoisy(true)
            .setWakeMode(C.WAKE_MODE_NETWORK)
            .setVideoScalingMode(C.VIDEO_SCALING_MODE_SCALE_TO_FIT)
            .setSeekBackIncrementMs(10_000)
            .setSeekForwardIncrementMs(10_000)
            .build()
        // El listener se registra en el bloque init al final de la clase
        // (debe declararse antes de usarse por el orden de inicialización de Kotlin).
    }

    // ─────────────────────────────────────────────────────────────────────────
    // API pública
    // ─────────────────────────────────────────────────────────────────────────

    fun prepare(channel: StreamChannel) {
        if (isReleased) return
        cancelScheduled()

        currentChannel = channel
        sessionId = channel.sessionId
        val detected = channel.detectFormat()
        formatCandidates = if (detected == StreamFormat.UNKNOWN) {
            StreamMediaSourceFactory.PROBE_ORDER
        } else {
            listOf(detected)
        }
        formatIndex = 0
        forceL3 = channel.forceWidevineL3 || usesTextureSurface
        networkRetries = 0
        decoderRetried = false
        hasBeenReady = false
        firstFrameRendered = false
        bufferingSince = 0L

        // Reset de pistas forzadas del canal anterior.
        trackSelector.parameters = trackSelector.parameters.buildUpon()
            .clearOverrides()
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
            .build()

        Log.i(TAG, "prepare session=$sessionId '${channel.name}' format=$detected drm=${channel.drmScheme}")
        loadSource()
    }

    fun play() {
        if (isReleased) return
        if (player.playbackState == Player.STATE_IDLE && currentChannel != null) {
            // Tras un error o stop: re-preparar en lugar de quedar en negro.
            if (isLive) player.seekToDefaultPosition()
            player.prepare()
        } else if (player.playbackState == Player.STATE_ENDED) {
            player.seekToDefaultPosition()
        }
        player.play()
    }

    fun pause() { if (!isReleased) player.pause() }

    fun stop() {
        cancelScheduled()
        if (!isReleased) player.stop()
    }

    fun seekTo(positionMs: Long) {
        if (isReleased || !player.isCurrentMediaItemSeekable) return
        player.seekTo(positionMs.coerceAtLeast(0L))
    }

    fun seekToLiveEdge() {
        if (!isReleased) player.seekToDefaultPosition()
    }

    fun setVolume(v: Float) { if (!isReleased) player.volume = v.coerceIn(0f, 1f) }

    fun setPlaybackSpeed(speed: Float) {
        if (!isReleased) player.playbackParameters = PlaybackParameters(speed.coerceIn(0.25f, 2f))
    }

    /**
     * Selecciona una pista concreta.
     *
     * @param trackType  C.TRACK_TYPE_VIDEO | C.TRACK_TYPE_AUDIO | C.TRACK_TYPE_TEXT
     * @param groupIndex índice GLOBAL del grupo en `player.currentTracks.groups`
     *                   (el mismo que se envía a Flutter). -1 = automático / desactivar texto.
     * @param trackIndex índice del formato dentro del grupo.
     */
    fun setTrack(trackType: Int, groupIndex: Int, trackIndex: Int) {
        if (isReleased) return
        val builder = trackSelector.parameters.buildUpon()

        if (groupIndex < 0 || trackIndex < 0) {
            builder.clearOverridesOfType(trackType)
            if (trackType == C.TRACK_TYPE_TEXT) builder.setTrackTypeDisabled(C.TRACK_TYPE_TEXT, true)
            trackSelector.parameters = builder.build()
            return
        }

        val groups = player.currentTracks.groups
        val group = groups.getOrNull(groupIndex)
        if (group == null || group.type != trackType || trackIndex >= group.length) {
            Log.w(TAG, "setTrack: índice inválido type=$trackType group=$groupIndex track=$trackIndex")
            return
        }
        builder
            .setTrackTypeDisabled(trackType, false)
            .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, trackIndex))
        trackSelector.parameters = builder.build()
    }

    /**
     * Fija un límite de resolución / bitrate de video, o maxHeight <= 0 para Automático.
     */
    fun setPreferredVideoQuality(maxHeight: Int, maxBitrate: Int) {
        if (isReleased) return
        trackSelector.parameters = trackSelector.parameters.buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .apply {
                if (maxHeight <= 0) clearVideoSizeConstraints() else setMaxVideoSize(Int.MAX_VALUE, maxHeight)
                setMaxVideoBitrate(if (maxBitrate > 0) maxBitrate else Int.MAX_VALUE)
            }
            .build()
    }

    fun release() {
        if (isReleased) return
        isReleased = true
        cancelScheduled()
        eventListener = null
        player.removeListener(playerListener)
        player.stop()
        player.clearMediaItems()
        player.release()
        currentChannel = null
        Log.i(TAG, "Player liberado")
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Carga y recuperación
    // ─────────────────────────────────────────────────────────────────────────

    private fun loadSource() {
        val channel = currentChannel ?: return
        try {
            val source = StreamMediaSourceFactory.createMediaSource(appContext, channel, currentFormat, forceL3)
            player.setMediaSource(source, /* resetPosition = */ true)
            player.playWhenReady = true
            player.prepare()
            emit("loading", "format" to currentFormat.name, "drm" to channel.drmScheme.name, "forceL3" to forceL3)
        } catch (e: Throwable) {
            val info = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(channel, info)
            emitError(info)
        }
    }

    /** Reintenta sobre la misma fuente (red caída, stall, behind-live-window). */
    private fun recoverInPlace() {
        if (isReleased || currentChannel == null) return
        Log.d(TAG, "Recuperando reproducción (retry=$networkRetries)")
        if (isLive || !hasBeenReady) player.seekToDefaultPosition()
        player.playWhenReady = true
        player.prepare()
    }

    private fun handleError(error: PlaybackException) {
        val channel = currentChannel
        val info = PlayerErrorMapper.map(error)
        PlayerErrorMapper.logError(channel, info)

        // 1. Live: nos quedamos fuera de la ventana DVR → volver al borde.
        if (info.errorCode == PlayerErrorMapper.ERROR_BEHIND_LIVE_WINDOW) {
            player.seekToDefaultPosition()
            player.prepare()
            return
        }

        // 2. Formato inferido incorrecto → probar el siguiente candidato.
        if (!hasBeenReady && PlayerErrorMapper.isFormatMismatch(info) && formatIndex + 1 < formatCandidates.size) {
            formatIndex++
            Log.w(TAG, "Formato no válido, probando ${currentFormat.name}")
            emit("retrying", "reason" to "format", "format" to currentFormat.name)
            loadSource()
            return
        }

        // 3. Widevine L1 con problemas (o decoder seguro) → forzar L3.
        val isWidevine = channel?.drmScheme == DrmScheme.WIDEVINE
        if (isWidevine && !forceL3 && PivoteDrmManager.widevineSecurityLevel == "L1" &&
            (PlayerErrorMapper.isDrmError(info) || info.errorCode == PlayerErrorMapper.ERROR_DECODER)
        ) {
            forceL3 = true
            Log.w(TAG, "Widevine L1 falló (${info.errorCode}); reintentando con L3")
            emit("retrying", "reason" to "widevine_l3")
            loadSource()
            return
        }

        // 4. Decoder: un reintento completo (el fallback de decoder ya está activo).
        if (info.errorCode == PlayerErrorMapper.ERROR_DECODER && !decoderRetried) {
            decoderRetried = true
            emit("retrying", "reason" to "decoder")
            loadSource()
            return
        }

        // 5. Red transitoria → backoff exponencial en el mismo servidor.
        if (PlayerErrorMapper.isTransientNetwork(info) && networkRetries < MAX_NETWORK_RETRIES) {
            val delay = BASE_RETRY_MS shl networkRetries
            networkRetries++
            Log.w(TAG, "Error de red, reintento $networkRetries/$MAX_NETWORK_RETRIES en ${delay}ms")
            emit("retrying", "reason" to "network", "attempt" to networkRetries, "delayMs" to delay)
            mainHandler.removeCallbacks(retryRunnable)
            mainHandler.postDelayed(retryRunnable, delay)
            return
        }

        // 6. Fatal → Flutter decide (siguiente servidor / mensaje al usuario).
        emitError(info)
    }

    /** Detecta buffering infinito (CDN colgada sin error explícito). */
    private fun checkStall() {
        if (player.playbackState != Player.STATE_BUFFERING || !player.playWhenReady || !hasBeenReady) {
            bufferingSince = 0L
            return
        }
        val now = SystemClock.elapsedRealtime()
        if (bufferingSince == 0L) bufferingSince = now
        if (now - bufferingSince > STALL_TIMEOUT_MS) {
            bufferingSince = 0L
            if (networkRetries < MAX_NETWORK_RETRIES) {
                networkRetries++
                Log.w(TAG, "Stall de ${STALL_TIMEOUT_MS}ms detectado; re-preparando")
                emit("retrying", "reason" to "stall", "attempt" to networkRetries)
                player.stop()
                recoverInPlace()
            } else {
                emitError(PlayerErrorInfo(PlayerErrorMapper.ERROR_NETWORK, "Stall: buffering sin progreso"))
            }
        }
    }

    private fun cancelScheduled() {
        mainHandler.removeCallbacks(retryRunnable)
        mainHandler.removeCallbacks(tickRunnable)
    }

    private fun startTicker() {
        mainHandler.removeCallbacks(tickRunnable)
        mainHandler.post(tickRunnable)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Listener de ExoPlayer
    // ─────────────────────────────────────────────────────────────────────────

    private val playerListener = object : Player.Listener {

        override fun onPlaybackStateChanged(state: Int) {
            if (isReleased) return
            emitState()
            when (state) {
                Player.STATE_READY -> {
                    networkRetries = 0
                    bufferingSince = 0L
                    if (!hasBeenReady) {
                        hasBeenReady = true
                        val vs = player.videoSize
                        emit(
                            "ready",
                            "durationMs" to durationMs,
                            "isLive" to isLive,
                            "isSeekable" to player.isCurrentMediaItemSeekable,
                            "videoWidth" to vs.width,
                            "videoHeight" to vs.height,
                            "format" to currentFormat.name
                        )
                    }
                    startTicker()
                }
                Player.STATE_BUFFERING -> startTicker()
                Player.STATE_ENDED -> {
                    mainHandler.removeCallbacks(tickRunnable)
                    if (isLive && networkRetries < MAX_NETWORK_RETRIES) {
                        // Algunos HLS "live" mal formados terminan: reconectar.
                        networkRetries++
                        recoverInPlace()
                    } else {
                        emit("ended")
                    }
                }
                Player.STATE_IDLE -> mainHandler.removeCallbacks(tickRunnable)
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (!isReleased) emitState()
        }

        override fun onPlayerError(error: PlaybackException) {
            if (!isReleased) handleError(error)
        }

        override fun onRenderedFirstFrame() {
            if (isReleased) return
            if (!firstFrameRendered) {
                firstFrameRendered = true
                Log.i(TAG, "Primer frame renderizado (${player.videoSize.width}x${player.videoSize.height})")
            }
            emit("firstFrame")
        }

        override fun onVideoSizeChanged(videoSize: VideoSize) {
            if (isReleased || videoSize.width == 0 || videoSize.height == 0) return
            emit(
                "videoSize",
                "videoWidth" to videoSize.width,
                "videoHeight" to videoSize.height,
                "pixelRatio" to videoSize.pixelWidthHeightRatio.toDouble()
            )
        }

        override fun onTracksChanged(tracks: Tracks) {
            if (!isReleased) emitTracks(tracks)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Emisión de eventos
    // ─────────────────────────────────────────────────────────────────────────

    private fun emitState() {
        val stateStr = when (player.playbackState) {
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY     -> "ready"
            Player.STATE_ENDED     -> "ended"
            else                   -> "idle"
        }
        emit("stateChanged", "playbackState" to stateStr, "isPlaying" to player.isPlaying)
    }

    private fun emitError(info: PlayerErrorInfo) {
        emit(
            "error",
            "errorCode" to info.errorCode,
            "message" to info.technicalMessage,
            "userMessage" to info.userMessage,
            "httpStatus" to info.httpStatus,
            "isFatal" to true
        )
    }

    private fun emitTracks(tracks: Tracks) {
        val video = mutableListOf<Map<String, Any?>>()
        val audio = mutableListOf<Map<String, Any?>>()
        val text  = mutableListOf<Map<String, Any?>>()
        var hasVideoGroup = false
        var hasSupportedVideo = false

        tracks.groups.forEachIndexed { groupIdx, group ->
            if (group.type == C.TRACK_TYPE_VIDEO) hasVideoGroup = true
            for (trackIdx in 0 until group.length) {
                val f: Format = group.getTrackFormat(trackIdx)
                val supported = group.isTrackSupported(trackIdx, /* allowExceedsCapabilities = */ true)
                if (group.type == C.TRACK_TYPE_VIDEO && supported) hasSupportedVideo = true
                val entry = mapOf(
                    "groupIndex" to groupIdx,
                    "trackIndex" to trackIdx,
                    "isSelected" to group.isTrackSelected(trackIdx),
                    "isSupported" to supported,
                    "bitrate" to f.bitrate.coerceAtLeast(0),
                    "width" to f.width.coerceAtLeast(0),
                    "height" to f.height.coerceAtLeast(0),
                    "frameRate" to (if (f.frameRate > 0) f.frameRate.toDouble() else 0.0),
                    "channels" to f.channelCount.coerceAtLeast(0),
                    "language" to (f.language ?: ""),
                    "label" to (f.label ?: ""),
                    "mimeType" to (f.sampleMimeType ?: ""),
                    "codecs" to (f.codecs ?: "")
                )
                when (group.type) {
                    C.TRACK_TYPE_VIDEO -> video.add(entry)
                    C.TRACK_TYPE_AUDIO -> audio.add(entry)
                    C.TRACK_TYPE_TEXT  -> text.add(entry)
                }
            }
        }

        if (hasVideoGroup && !hasSupportedVideo) {
            Log.w(TAG, "El stream tiene video pero ningún formato es decodificable en este dispositivo")
        }

        emit(
            "tracksChanged",
            "videoTracks" to video,
            "audioTracks" to audio,
            "textTracks" to text,
            "videoUnsupported" to (hasVideoGroup && !hasSupportedVideo)
        )
    }

    private fun emit(event: String, vararg pairs: Pair<String, Any?>) {
        val sink = eventListener ?: return
        val data = HashMap<String, Any?>(pairs.size + 2)
        data["event"] = event
        data["sessionId"] = sessionId
        pairs.forEach { data[it.first] = it.second }
        if (Looper.myLooper() == Looper.getMainLooper()) sink(data) else mainHandler.post { eventListener?.invoke(data) }
    }

    init {
        player.addListener(playerListener)
    }
}
