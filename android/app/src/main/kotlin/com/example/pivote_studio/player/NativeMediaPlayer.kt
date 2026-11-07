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
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Motor central de reproducción basado en Media3 ExoPlayer.
 *
 * Garantías de diseño:
 *   • UNA sola instancia de ExoPlayer por PlatformView.
 *   • Arranque ultrarrápido de buffer ideal para zapping IPTV y enlaces M3U8 claros.
 *   • Reenvío garantizado de estado al conectar el EventChannel (evita "loading infinito").
 *   • MultiSession DRM, presets automáticos de headers para HLS/MPD y fallback inteligente de formatos.
 */
@OptIn(UnstableApi::class)
class NativeMediaPlayer(context: Context) {

    companion object {
        private const val TAG = "PivoteExoPlayer"
        private const val MAX_NETWORK_RETRIES = 2
        private const val BASE_RETRY_MS       = 700L
        private const val POSITION_TICK_MS    = 500L
        private const val STALL_TIMEOUT_MS    = 14_000L
    }

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Callback de eventos hacia la capa Flutter (siempre en hilo principal). */
    var eventListener: ((Map<String, Any?>) -> Unit)? = null

    /**
     * true si la vista usa TextureView: una TextureView no puede mostrar salida de un
     * decodificador seguro de hardware L1, así que Widevine se fuerza a L3 para evitar pantalla negra.
     */
    var usesTextureSurface: Boolean = true

    // ── Core ─────────────────────────────────────────────────────────────────
    private val trackSelector = DefaultTrackSelector(appContext).apply {
        parameters = buildUponParameters()
            .setAllowVideoMixedMimeTypeAdaptiveness(true)
            .setAllowVideoNonSeamlessAdaptiveness(true)
            .setAllowAudioMixedMimeTypeAdaptiveness(true)
            .setAllowAudioNonSeamlessAdaptiveness(true)
            .setExceedVideoConstraintsIfNecessary(true)
            .setExceedAudioConstraintsIfNecessary(true)
            .setExceedRendererCapabilitiesIfNecessary(true)
            .setTunnelingEnabled(false)
            .setPreferredAudioLanguages("es", "spa", "es-419", "und", "en")
            .setPreferredTextLanguages("es", "spa")
            .setSelectUndeterminedTextLanguage(false)
            .build()
    }

    val player: ExoPlayer = buildPlayer()

    // ── Estado de sesión ────────────────────────────────────────────────────
    private var currentChannel: StreamChannel? = null
    private var initialHeaders: Map<String, String> = emptyMap()
    private var sessionId = 0
    private var formatCandidates: List<StreamFormat> = emptyList()
    private var formatIndex = 0
    private var mpdHeaderPresetIndex = -1
    private var hlsHeaderPresetIndex = -1
    private var allowChunklessHls = true
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
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)

        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs */                      8_000,
                /* maxBufferMs */                     36_000,
                /* bufferForPlaybackMs */                550,
                /* bufferForPlaybackAfterRebufferMs */ 1_400
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(10_000, false)
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
    }

    // ─────────────────────────────────────────────────────────────────────────
    // API pública
    // ─────────────────────────────────────────────────────────────────────────

    fun prepare(channel: StreamChannel) {
        if (isReleased) return
        cancelScheduled()

        currentChannel = channel
        initialHeaders = LinkedHashMap(channel.headers)
        sessionId = channel.sessionId
        val detected = channel.detectFormat()
        formatCandidates = when {
            detected == StreamFormat.UNKNOWN -> StreamMediaSourceFactory.PROBE_ORDER
            !channel.hasDrm && detected == StreamFormat.HLS ->
                listOf(StreamFormat.HLS, StreamFormat.PROGRESSIVE, StreamFormat.DASH)
            !channel.hasDrm && detected == StreamFormat.DASH ->
                listOf(StreamFormat.DASH, StreamFormat.HLS, StreamFormat.PROGRESSIVE)
            !channel.hasDrm && detected == StreamFormat.PROGRESSIVE ->
                listOf(StreamFormat.PROGRESSIVE, StreamFormat.HLS)
            else -> listOf(detected)
        }
        formatIndex = 0
        mpdHeaderPresetIndex = -1
        hlsHeaderPresetIndex = -1
        allowChunklessHls = true
        forceL3 = channel.forceWidevineL3 || usesTextureSurface
        networkRetries = 0
        decoderRetried = false
        hasBeenReady = false
        firstFrameRendered = false
        bufferingSince = 0L

        trackSelector.parameters = trackSelector.parameters.buildUpon()
            .clearOverrides()
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
            .build()

        Log.i(TAG, "prepare session=$sessionId '${channel.name}' format=$detected candidates=$formatCandidates drm=${channel.drmScheme}")
        loadSource()
    }

    /**
     * Sincroniza el estado actual con Flutter cuando el EventChannel acaba de suscribirse.
     */
    fun syncStateToFlutter() {
        if (isReleased) return
        emitState()
        if (hasBeenReady || player.playbackState == Player.STATE_READY) {
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
        if (firstFrameRendered) {
            emit("firstFrame")
        }
        if (player.currentTracks.groups.isNotEmpty()) {
            emitTracks(player.currentTracks)
        }
    }

    fun play() {
        if (isReleased) return
        if (player.playbackState == Player.STATE_IDLE && currentChannel != null) {
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
            val source = StreamMediaSourceFactory.createMediaSource(
                context = appContext,
                channel = channel,
                format = currentFormat,
                forceL3 = forceL3,
                allowChunklessHls = allowChunklessHls
            )
            player.stop()
            player.clearMediaItems()
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

        // 2. Si es HLS/M3U8 y falla el extractor/manifiesto/contenedor en preparación chunkless,
        //    reintentar desactivando chunklessPreparation para que ExoPlayer inspeccione los segmentos TS reales.
        if (!hasBeenReady &&
            currentFormat == StreamFormat.HLS &&
            allowChunklessHls &&
            (info.errorCode == PlayerErrorMapper.ERROR_MANIFEST ||
                info.errorCode == PlayerErrorMapper.ERROR_UNSUPPORTED_FORMAT ||
                info.errorCode == PlayerErrorMapper.ERROR_DECODER ||
                info.errorCode == PlayerErrorMapper.ERROR_SOURCE)
        ) {
            allowChunklessHls = false
            Log.w(TAG, "HLS chunkless falló (${info.errorCode}); reintentando con inspección completa de TS")
            emit("retrying", "reason" to "hls_full_extractor")
            loadSource()
            return
        }

        // 3. Si es HLS/M3U8 claro y falla por HTTP (403/401/400/404), manifiesto o red,
        //    probar automáticamente los perfiles de headers HLS (Same-Origin, VLC/IPTV sin Origin, etc.)
        if (!hasBeenReady &&
            currentFormat == StreamFormat.HLS &&
            channel != null &&
            (info.errorCode == PlayerErrorMapper.ERROR_HTTP ||
                info.errorCode == PlayerErrorMapper.ERROR_MANIFEST ||
                info.errorCode == PlayerErrorMapper.ERROR_NETWORK ||
                info.errorCode == PlayerErrorMapper.ERROR_UNSUPPORTED_FORMAT)
        ) {
            val hlsPresets = StreamHttpDataSourceFactory.buildHlsHeaderPresets(channel.originalUrl)
            if (hlsHeaderPresetIndex + 1 < hlsPresets.size) {
                hlsHeaderPresetIndex++
                val preset = hlsPresets[hlsHeaderPresetIndex]
                val updatedHeaders = LinkedHashMap(initialHeaders).apply {
                    remove("Origin")
                    remove("Referer")
                    remove("User-Agent")
                    remove("__STRIP_ORIGIN_REFERER__")
                    remove("__STRIP_ORIGIN_ONLY__")
                    putAll(preset)
                }
                currentChannel = channel.copy(headers = updatedHeaders)
                Log.w(TAG, "HLS M3U8 falló (${info.errorCode} HTTP=${info.httpStatus}); reintentando con perfil HLS #${hlsHeaderPresetIndex + 1}")
                emit("retrying", "reason" to "hls_headers_preset", "preset" to (hlsHeaderPresetIndex + 1))
                loadSource()
                return
            }
        }

        // 4. Si es DASH/MPD y falla la carga inicial, probar los presets de headers MPD (Flow AR, Flow PY, PrimeVideo)
        if (!hasBeenReady &&
            currentFormat == StreamFormat.DASH &&
            (info.errorCode == PlayerErrorMapper.ERROR_HTTP ||
                info.errorCode == PlayerErrorMapper.ERROR_MANIFEST ||
                info.errorCode == PlayerErrorMapper.ERROR_MPD_LOAD ||
                info.errorCode == PlayerErrorMapper.ERROR_NETWORK) &&
            mpdHeaderPresetIndex + 1 < StreamHttpDataSourceFactory.MPD_HEADER_PRESETS.size
        ) {
            mpdHeaderPresetIndex++
            var preset = StreamHttpDataSourceFactory.MPD_HEADER_PRESETS[mpdHeaderPresetIndex]
            if (channel != null &&
                channel.headers["Referer"] == preset["Referer"] &&
                mpdHeaderPresetIndex + 1 < StreamHttpDataSourceFactory.MPD_HEADER_PRESETS.size
            ) {
                mpdHeaderPresetIndex++
                preset = StreamHttpDataSourceFactory.MPD_HEADER_PRESETS[mpdHeaderPresetIndex]
            }
            if (channel != null) {
                val updatedHeaders = LinkedHashMap(initialHeaders).apply {
                    remove("Origin")
                    remove("Referer")
                    remove("User-Agent")
                    putAll(preset)
                }
                currentChannel = channel.copy(headers = updatedHeaders)
                Log.w(TAG, "MPD falló (${info.errorCode} HTTP=${info.httpStatus}); reintentando con preset MPD #${mpdHeaderPresetIndex + 1}")
                emit("retrying", "reason" to "mpd_headers_preset", "preset" to (mpdHeaderPresetIndex + 1))
                loadSource()
                return
            }
        }

        // 5. Formato inferido incorrecto → probar el siguiente candidato (ej. HLS -> PROGRESSIVE TS -> DASH).
        if (!hasBeenReady && PlayerErrorMapper.isFormatMismatch(info) && formatIndex + 1 < formatCandidates.size) {
            formatIndex++
            if (channel != null) {
                currentChannel = channel.copy(headers = LinkedHashMap(initialHeaders))
            }
            Log.w(TAG, "Formato no válido, probando ${currentFormat.name}")
            emit("retrying", "reason" to "format", "format" to currentFormat.name)
            loadSource()
            return
        }

        // 6. Widevine L1 con problemas → forzar L3.
        val isWidevine = channel?.drmScheme == DrmScheme.WIDEVINE
        if (isWidevine && !forceL3 &&
            (PlayerErrorMapper.isDrmError(info) || info.errorCode == PlayerErrorMapper.ERROR_DECODER)
        ) {
            forceL3 = true
            Log.w(TAG, "Widevine L1 falló (${info.errorCode}); reintentando con L3")
            emit("retrying", "reason" to "widevine_l3")
            loadSource()
            return
        }

        // 7. Decoder: un reintento completo.
        if (info.errorCode == PlayerErrorMapper.ERROR_DECODER && !decoderRetried) {
            decoderRetried = true
            allowChunklessHls = false
            emit("retrying", "reason" to "decoder")
            loadSource()
            return
        }

        // 8. Red transitoria → reintento rápido.
        if (PlayerErrorMapper.isTransientNetwork(info) && networkRetries < MAX_NETWORK_RETRIES) {
            val delay = BASE_RETRY_MS shl networkRetries
            networkRetries++
            Log.w(TAG, "Error de red, reintento $networkRetries/$MAX_NETWORK_RETRIES en ${delay}ms")
            emit("retrying", "reason" to "network", "attempt" to networkRetries, "delayMs" to delay)
            mainHandler.removeCallbacks(retryRunnable)
            mainHandler.postDelayed(retryRunnable, delay)
            return
        }

        // 9. Fatal → Flutter decide.
        emitError(info)
    }

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
                Log.w(TAG, "Stall detectado; re-preparando")
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
                    startTicker()
                }
                Player.STATE_BUFFERING -> startTicker()
                Player.STATE_ENDED -> {
                    mainHandler.removeCallbacks(tickRunnable)
                    if (isLive && networkRetries < MAX_NETWORK_RETRIES) {
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
            firstFrameRendered = true
            hasBeenReady = true
            Log.i(TAG, "Primer frame renderizado (${player.videoSize.width}x${player.videoSize.height})")
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
