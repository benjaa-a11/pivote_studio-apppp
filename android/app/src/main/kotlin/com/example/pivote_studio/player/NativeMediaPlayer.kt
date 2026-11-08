package com.example.pivote_studio.player

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
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
import androidx.media3.ui.PlayerView
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.data.StreamFormat
import com.example.pivote_studio.network.StreamHttpDataSourceFactory
import com.example.pivote_studio.ui.NativePlayerView
import java.lang.ref.WeakReference
import java.util.concurrent.Executors

/**
 * Motor nativo único (Singleton) de reproducción basado en Media3 ExoPlayer.
 *
 * Garantías de arquitectura:
 *   • UNA SOLA instancia de ExoPlayer en toda la aplicación, reutilizada en cada zapping
 *     mediante `setMediaSource` + `prepare` (sin destruir ni recrear decodificadores).
 *   • Transferencia limpia de superficie mediante `PlayerView.switchTargetView` (cero
 *     reproductores superpuestos o fantasmas).
 *   • Arranque rápido para Live: buffers cortos, bitrate inicial conservador en el primer
 *     frame y subida progresiva por ABR.
 *   • Diagnóstico y corrección automática de "solo audio sin video" (decoder fallback,
 *     watchdog de primer frame, bajada escalonada de perfil/resolución, cambio SurfaceView/L3
 *     y notificación de failover a Dart).
 *   • Detección de stream congelado tanto en buffering como en STATE_READY sin avance de posición.
 *   • Monitoreo nativo de red (Wi-Fi vs Datos móviles y reconexión automática al borde en vivo).
 */
@OptIn(UnstableApi::class)
class NativeMediaPlayer private constructor(context: Context) {

    companion object {
        private const val SUBTAG = "Engine"

        @Volatile
        private var instance: NativeMediaPlayer? = null

        fun getInstance(context: Context): NativeMediaPlayer {
            return instance ?: synchronized(this) {
                instance ?: NativeMediaPlayer(context.applicationContext).also {
                    NativePlayerConfig.initDebugFlag(context.applicationContext)
                    instance = it
                }
            }
        }
    }

    private val appContext = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val ioExecutor = Executors.newSingleThreadExecutor()

    /** Callback de eventos hacia la capa Flutter (siempre despachado en el hilo principal). */
    var eventListener: ((Map<String, Any?>) -> Unit)? = null

    /** Referencia débil a la vista actualmente vinculada al motor único. */
    private var attachedViewRef: WeakReference<NativePlayerView>? = null

    val usesTextureSurface: Boolean
        get() = attachedViewRef?.get()?.isUsingTextureView ?: true

    // ── Core TrackSelector (SIN exceedRendererCapabilities para evitar audio sin video) ──
    private val trackSelector = DefaultTrackSelector(appContext).apply {
        parameters = buildUponParameters()
            .setAllowVideoMixedMimeTypeAdaptiveness(true)
            .setAllowVideoNonSeamlessAdaptiveness(true)
            .setAllowAudioMixedMimeTypeAdaptiveness(true)
            .setAllowAudioNonSeamlessAdaptiveness(true)
            .setExceedVideoConstraintsIfNecessary(true)
            .setExceedAudioConstraintsIfNecessary(true)
            // CRÍTICO: false para impedir que ExoPlayer seleccione perfiles H.264/HEVC 10-bit/4K
            // que el SoC del teléfono no soporta en hardware (causa principal de solo audio sin video).
            .setExceedRendererCapabilitiesIfNecessary(false)
            .setTunnelingEnabled(false)
            .setPreferredAudioLanguages("es", "spa", "es-419", "und", "en")
            .setPreferredTextLanguages("es", "spa")
            .setSelectUndeterminedTextLanguage(false)
            .build()
    }

    val player: ExoPlayer = buildPlayer()

    // ── Estado de sesión y canal actual ─────────────────────────────────────
    private var currentChannel: StreamChannel? = null
    private var initialHeaders: Map<String, String> = emptyMap()
    @Volatile
    private var sessionId = 0
    private var formatCandidates: List<StreamFormat> = emptyList()
    private var formatIndex = 0
    private var mpdHeaderPresetIndex = -1
    private var hlsHeaderPresetIndex = -1
    private var allowChunklessHls = true
    private var forceL3 = false
    private var triedProxy = false
    private var networkRetries = 0
    private var decoderRetried = false
    private var audioOnlyRecoveryStep = 0
    private var hasBeenReady = false
    private var firstFrameRendered = false
    private var hasVideoTrackGroup = false

    // ── Monitoreo de salud (Stall / Frozen stream) ──────────────────────────
    private var bufferingSince = 0L
    private var lastObservedPositionMs = -1L
    private var lastPositionAdvanceRealtime = 0L
    private var pausedAtRealtime = 0L

    // ── Calidad y Red (Wi-Fi vs Datos móviles) ──────────────────────────────
    private var userMaxVideoHeight = -1
    private var userMaxVideoBitrate = -1
    private var isCellularNetwork = false
    private var hadNetworkLoss = false

    private val currentFormat: StreamFormat
        get() = formatCandidates.getOrElse(formatIndex) { StreamFormat.PROGRESSIVE }

    // ── Runnables programados ───────────────────────────────────────────────
    private val retryRunnable = Runnable { recoverInPlace() }

    private val audioWithoutVideoRunnable = Runnable {
        onAudioWithoutVideoTimeout()
    }

    private val tickRunnable = object : Runnable {
        override fun run() {
            if (currentChannel == null) return
            val pos = player.currentPosition.coerceAtLeast(0L)
            val buf = player.bufferedPosition.coerceAtLeast(0L)
            val liveOffset = if (isLive) player.currentLiveOffset.takeIf { it != C.TIME_UNSET } ?: -1L else -1L

            emit(
                "position",
                "positionMs" to pos,
                "bufferedMs" to buf,
                "durationMs" to durationMs,
                "liveOffsetMs" to liveOffset,
                "isLive" to isLive,
                "isSeekable" to player.isCurrentMediaItemSeekable
            )
            checkStallAndFrozen(pos)
            mainHandler.postDelayed(this, NativePlayerConfig.HEALTH_TICK_MS)
        }
    }

    // ── Propiedades públicas ────────────────────────────────────────────────
    val isPlaying: Boolean get() = player.isPlaying
    val isLive: Boolean get() = player.isCurrentMediaItemLive || player.isCurrentMediaItemDynamic
    val durationMs: Long
        get() {
            val d = player.duration
            return if (d == C.TIME_UNSET || d <= 0L) -1L else d
        }

    // ─────────────────────────────────────────────────────────────────────────
    // Construcción del ExoPlayer Único
    // ─────────────────────────────────────────────────────────────────────────

    private fun buildPlayer(): ExoPlayer {
        val renderers = DefaultRenderersFactory(appContext)
            .setEnableDecoderFallback(true)
            .setExtensionRendererMode(DefaultRenderersFactory.EXTENSION_RENDERER_MODE_PREFER)

        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs = */ NativePlayerConfig.MIN_BUFFER_MS,
                /* maxBufferMs = */ NativePlayerConfig.MAX_BUFFER_MS,
                /* bufferForPlaybackMs = */ NativePlayerConfig.BUFFER_FOR_PLAYBACK_MS,
                /* bufferForPlaybackAfterRebufferMs = */ NativePlayerConfig.BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(NativePlayerConfig.BACK_BUFFER_MS, /* retainBackBufferFromKeyframe = */ false)
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
    // Gestión de Surface y Vistas (Cero reproductores superpuestos)
    // ─────────────────────────────────────────────────────────────────────────

    fun attachView(newView: NativePlayerView) {
        val oldView = attachedViewRef?.get()
        if (oldView === newView) {
            if (newView.playerView.player !== player) {
                newView.playerView.player = player
            }
            return
        }
        PlayerView.switchTargetView(player, oldView?.playerView, newView.playerView)
        attachedViewRef = WeakReference(newView)
        NativePlayerConfig.logD(SUBTAG, "Vista vinculada al motor único (texture=${newView.isUsingTextureView})")
    }

    fun detachView(view: NativePlayerView) {
        val current = attachedViewRef?.get()
        if (current === view) {
            view.playerView.player = null
            attachedViewRef = null
            NativePlayerConfig.logD(SUBTAG, "Vista desvinculada del motor único")
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // API Pública (Zapping, Reproducción, Tracks y Calidad)
    // ─────────────────────────────────────────────────────────────────────────

    fun prepare(channel: StreamChannel) {
        cancelScheduled()

        currentChannel = channel
        initialHeaders = LinkedHashMap(channel.headers)
        val activeSession = channel.sessionId
        sessionId = activeSession

        mpdHeaderPresetIndex = -1
        hlsHeaderPresetIndex = -1
        allowChunklessHls = true
        triedProxy = false
        networkRetries = 0
        decoderRetried = false
        audioOnlyRecoveryStep = 0
        hasBeenReady = false
        firstFrameRendered = false
        hasVideoTrackGroup = false
        bufferingSince = 0L
        lastObservedPositionMs = -1L
        lastPositionAdvanceRealtime = 0L

        // Si el canal es Widevine y no pide L3 explícitamente, usamos SurfaceView para soportar L1 hardware
        // o si estamos en TextureView forzamos L3 inicialmente.
        forceL3 = channel.forceWidevineL3 || usesTextureSurface

        // Selección inicial de calidad conservadora para minimizar tiempo hasta el primer frame
        applyInitialConservativeTrackParameters()

        // Detener de inmediato la conexión anterior para liberar socket y decodificador
        player.stop()
        player.clearMediaItems()

        val detected = channel.detectFormat()
        if (detected != StreamFormat.UNKNOWN) {
            formatCandidates = buildFormatCandidates(detected, channel.hasDrm)
            formatIndex = 0
            NativePlayerConfig.logI(
                SUBTAG,
                "prepare session=$activeSession '${channel.name}' format=$detected candidates=$formatCandidates drm=${channel.drmScheme}"
            )
            loadSource()
        } else {
            // URL sin extensión clara: detectar por MIME/contenido en background y hacer fallback DASH -> HLS -> TS
            emit("loading", "format" to "PROBING", "drm" to channel.drmScheme.name, "forceL3" to forceL3)
            ioExecutor.execute {
                val sniffed = StreamHttpDataSourceFactory.sniffStreamFormat(channel.originalUrl, channel.headers)
                mainHandler.post {
                    // Evitar condición de carrera si el usuario cambió de canal durante el sniff
                    if (sessionId != activeSession || currentChannel == null) return@post
                    formatCandidates = if (sniffed != null) {
                        buildFormatCandidates(sniffed, channel.hasDrm)
                    } else {
                        StreamMediaSourceFactory.PROBE_ORDER
                    }
                    formatIndex = 0
                    NativePlayerConfig.logI(
                        SUBTAG,
                        "prepare(sniffed=$sniffed) session=$activeSession '${channel.name}' candidates=$formatCandidates"
                    )
                    loadSource()
                }
            }
        }
    }

    private fun buildFormatCandidates(primary: StreamFormat, hasDrm: Boolean): List<StreamFormat> {
        if (hasDrm) return listOf(primary)
        return when (primary) {
            StreamFormat.DASH -> listOf(StreamFormat.DASH, StreamFormat.HLS, StreamFormat.PROGRESSIVE)
            StreamFormat.HLS -> listOf(StreamFormat.HLS, StreamFormat.PROGRESSIVE, StreamFormat.DASH)
            StreamFormat.PROGRESSIVE -> listOf(StreamFormat.PROGRESSIVE, StreamFormat.HLS, StreamFormat.DASH)
            else -> StreamMediaSourceFactory.PROBE_ORDER
        }
    }

    /**
     * Precarga liviana (manifest warmup) del canal siguiente/anterior sin duplicar el ExoPlayer.
     * Calienta el DNS, TLS handshake y caché de borde del CDN en hilo de fondo.
     */
    fun preloadManifest(url: String, headers: Map<String, String>) {
        if (url.isBlank()) return
        ioExecutor.execute {
            runCatching {
                StreamHttpDataSourceFactory.sniffStreamFormat(url, headers)
                NativePlayerConfig.logD(SUBTAG, "Preload warmup completado para ${PlayerErrorMapper.sanitizeUrl(url)}")
            }
        }
    }

    fun syncStateToFlutter() {
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
        if (player.playbackState == Player.STATE_IDLE && currentChannel != null) {
            if (isLive) player.seekToDefaultPosition()
            player.prepare()
        } else if (player.playbackState == Player.STATE_ENDED) {
            player.seekToDefaultPosition()
        } else if (isLive && pausedAtRealtime > 0L) {
            // Regreso automático al borde en vivo tras una pausa larga
            val pausedDuration = SystemClock.elapsedRealtime() - pausedAtRealtime
            val liveOffset = player.currentLiveOffset
            if (pausedDuration > NativePlayerConfig.LIVE_EDGE_RESYNC_THRESHOLD_MS ||
                (liveOffset != C.TIME_UNSET && liveOffset > NativePlayerConfig.LIVE_EDGE_RESYNC_THRESHOLD_MS)
            ) {
                NativePlayerConfig.logI(SUBTAG, "Pausa larga en vivo (${pausedDuration}ms) → volviendo al live edge")
                player.seekToDefaultPosition()
            }
        }
        pausedAtRealtime = 0L
        player.play()
    }

    fun pause() {
        pausedAtRealtime = SystemClock.elapsedRealtime()
        player.pause()
    }

    fun stop() {
        cancelScheduled()
        currentChannel = null
        player.stop()
        player.clearMediaItems()
    }

    fun seekTo(positionMs: Long) {
        if (!player.isCurrentMediaItemSeekable) return
        player.seekTo(positionMs.coerceAtLeast(0L))
    }

    fun seekToLiveEdge() {
        player.seekToDefaultPosition()
        if (player.playbackState == Player.STATE_IDLE && currentChannel != null) {
            player.prepare()
        }
        player.play()
    }

    fun setVolume(v: Float) {
        player.volume = v.coerceIn(0f, 1f)
    }

    fun setPlaybackSpeed(speed: Float) {
        player.playbackParameters = PlaybackParameters(speed.coerceIn(0.25f, 2f))
    }

    fun setTrack(trackType: Int, groupIndex: Int, trackIndex: Int) {
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
            NativePlayerConfig.logW(SUBTAG, "setTrack: índice inválido type=$trackType group=$groupIndex track=$trackIndex")
            return
        }
        builder
            .setTrackTypeDisabled(trackType, false)
            .setOverrideForType(TrackSelectionOverride(group.mediaTrackGroup, trackIndex))
        trackSelector.parameters = builder.build()
    }

    fun setPreferredVideoQuality(maxHeight: Int, maxBitrate: Int) {
        userMaxVideoHeight = maxHeight
        userMaxVideoBitrate = maxBitrate
        applySteadyStateQualityConstraints()
    }

    private fun applyInitialConservativeTrackParameters() {
        val initialMaxBitrate = if (userMaxVideoBitrate > 0) {
            userMaxVideoBitrate.coerceAtMost(NativePlayerConfig.INITIAL_STARTUP_MAX_BITRATE)
        } else {
            NativePlayerConfig.INITIAL_STARTUP_MAX_BITRATE
        }

        trackSelector.parameters = trackSelector.parameters.buildUpon()
            .clearOverrides()
            .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, false)
            .setTrackTypeDisabled(C.TRACK_TYPE_TEXT, false)
            .setMaxVideoBitrate(initialMaxBitrate)
            .apply {
                if (userMaxVideoHeight > 0) {
                    setMaxVideoSize(Int.MAX_VALUE, userMaxVideoHeight)
                } else if (isCellularNetwork) {
                    setMaxVideoSize(Int.MAX_VALUE, NativePlayerConfig.CELLULAR_AUTO_MAX_HEIGHT)
                } else {
                    clearVideoSizeConstraints()
                }
            }
            .build()
    }

    /**
     * Una vez renderizado el primer frame, libera el tope de arranque rápido para que
     * el ABR suba progresivamente hasta el límite manual o el de la red actual (Wi-Fi vs Datos).
     */
    private fun applySteadyStateQualityConstraints() {
        val effectiveHeight = when {
            userMaxVideoHeight > 0 -> userMaxVideoHeight
            isCellularNetwork -> NativePlayerConfig.CELLULAR_AUTO_MAX_HEIGHT
            else -> Int.MAX_VALUE
        }
        val effectiveBitrate = when {
            userMaxVideoBitrate > 0 -> userMaxVideoBitrate
            isCellularNetwork -> NativePlayerConfig.CELLULAR_AUTO_MAX_BITRATE
            else -> Int.MAX_VALUE
        }

        trackSelector.parameters = trackSelector.parameters.buildUpon()
            .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
            .apply {
                if (effectiveHeight == Int.MAX_VALUE) clearVideoSizeConstraints()
                else setMaxVideoSize(Int.MAX_VALUE, effectiveHeight)
                setMaxVideoBitrate(effectiveBitrate)
            }
            .build()
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Carga de Fuente, Diagnóstico de "Solo Audio" y Recuperación
    // ─────────────────────────────────────────────────────────────────────────

    private fun loadSource(useProxy: Boolean = false) {
        val channel = currentChannel ?: return
        try {
            val source = StreamMediaSourceFactory.createMediaSource(
                context = appContext,
                channel = channel,
                format = currentFormat,
                forceL3 = forceL3,
                allowChunklessHls = allowChunklessHls,
                useProxy = useProxy
            )
            firstFrameRendered = false
            player.stop()
            player.clearMediaItems()
            player.setMediaSource(source, /* resetPosition = */ true)
            player.playWhenReady = true
            player.prepare()
            emit(
                "loading",
                "format" to currentFormat.name,
                "drm" to channel.drmScheme.name,
                "forceL3" to forceL3,
                "proxied" to useProxy
            )
        } catch (e: Throwable) {
            val info = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(channel, info)
            emitError(info)
        }
    }

    private fun recoverInPlace() {
        if (currentChannel == null) return
        NativePlayerConfig.logD(SUBTAG, "Recuperando reproducción in-place (retry=$networkRetries)")
        if (isLive || !hasBeenReady) player.seekToDefaultPosition()
        player.playWhenReady = true
        player.prepare()
    }

    /**
     * Watchdog que se activa cuando el reproductor está en STATE_READY reproduciendo audio,
     * pero no ha renderizado ni un solo frame de video tras [NativePlayerConfig.AUDIO_WITHOUT_VIDEO_TIMEOUT_MS].
     */
    private fun onAudioWithoutVideoTimeout() {
        val channel = currentChannel ?: return
        if (firstFrameRendered || player.playbackState != Player.STATE_READY) return

        // Si el stream realmente es de solo audio (sin grupos de video y formato progresivo de audio), ignorar
        // (radios HLS/TS o canales realmente solo-audio no declaran pista de video)
        if (!hasVideoTrackGroup) return

        NativePlayerConfig.logW(
            SUBTAG,
            "Detectado SOLO AUDIO SIN VIDEO en '${channel.name}' (step=$audioOnlyRecoveryStep, drm=${channel.drmScheme}, l3=$forceL3)"
        )

        when (audioOnlyRecoveryStep) {
            0 -> {
                // Paso 1: Re-vincular la Surface y forzar un perfil de video menor (<= 540p)
                // por si el perfil H.264/HEVC alto falló silenciosamente en el hardware.
                audioOnlyRecoveryStep = 1
                trackSelector.parameters = trackSelector.parameters.buildUpon()
                    .clearOverridesOfType(C.TRACK_TYPE_VIDEO)
                    .setMaxVideoSize(960, 540)
                    .setMaxVideoBitrate(1_200_000)
                    .build()
                attachedViewRef?.get()?.refreshVideoSurface()
                emit("retrying", "reason" to "audio_only_downscale_surface")
                mainHandler.postDelayed(audioWithoutVideoRunnable, NativePlayerConfig.AUDIO_WITHOUT_VIDEO_TIMEOUT_MS)
            }
            1 -> {
                // Paso 2: Si tiene Widevine o usa TextureView, alternar L3 / SurfaceView o desactivar chunkless HLS
                audioOnlyRecoveryStep = 2
                if (channel.drmScheme == DrmScheme.WIDEVINE && usesTextureSurface) {
                    attachedViewRef?.get()?.ensureSurfaceType(useTexture = false)
                    forceL3 = false
                    NativePlayerConfig.logI(SUBTAG, "Conmutando a SurfaceView para Widevine L1")
                } else if (channel.drmScheme == DrmScheme.WIDEVINE && !forceL3) {
                    forceL3 = true
                } else if (currentFormat == StreamFormat.HLS && allowChunklessHls) {
                    allowChunklessHls = false
                }
                emit("retrying", "reason" to "audio_only_reprepare")
                loadSource(useProxy = triedProxy)
            }
            else -> {
                // Paso 3: El servidor entrega video corrupto o incompatible → emitir error fatal para
                // que el controlador en Dart conmute inmediatamente al siguiente servidor por prioridad.
                val info = PlayerErrorInfo(
                    errorCode = PlayerErrorMapper.ERROR_AUDIO_ONLY,
                    technicalMessage = "Timeout sin primer frame de video (solo audio detectado)"
                )
                PlayerErrorMapper.logError(channel, info)
                emitError(info)
            }
        }
    }

    private fun handleError(error: PlaybackException) {
        val channel = currentChannel
        val info = PlayerErrorMapper.map(error)
        PlayerErrorMapper.logError(channel, info)

        // 1. Live: nos quedamos fuera de la ventana DVR → volver al borde en vivo de inmediato.
        if (info.errorCode == PlayerErrorMapper.ERROR_BEHIND_LIVE_WINDOW) {
            NativePlayerConfig.logI(SUBTAG, "Fuera de ventana en vivo → seekToDefaultPosition()")
            player.seekToDefaultPosition()
            player.prepare()
            return
        }

        // 2. HLS chunkless falló en preparación → reintentar inspeccionando los segmentos TS reales.
        if (!hasBeenReady &&
            currentFormat == StreamFormat.HLS &&
            allowChunklessHls &&
            (info.errorCode == PlayerErrorMapper.ERROR_MANIFEST ||
                info.errorCode == PlayerErrorMapper.ERROR_UNSUPPORTED_FORMAT ||
                info.errorCode == PlayerErrorMapper.ERROR_DECODER ||
                info.errorCode == PlayerErrorMapper.ERROR_SOURCE)
        ) {
            allowChunklessHls = false
            NativePlayerConfig.logW(SUBTAG, "HLS chunkless falló (${info.errorCode}); reintentando con extractor TS completo")
            emit("retrying", "reason" to "hls_full_extractor")
            loadSource(useProxy = triedProxy)
            return
        }

        // 3. HLS claro con bloqueo HTTP (403/401/400) o manifiesto → probar perfiles de headers HLS.
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
                NativePlayerConfig.logW(
                    SUBTAG,
                    "HLS falló (${info.errorCode} HTTP=${info.httpStatus}); probando perfil HLS #${hlsHeaderPresetIndex + 1}"
                )
                emit("retrying", "reason" to "hls_headers_preset", "preset" to (hlsHeaderPresetIndex + 1))
                loadSource(useProxy = triedProxy)
                return
            }
        }

        // 4. DASH/MPD con fallo de carga inicial → probar presets de headers MPD (Flow AR, Flow PY, PrimeVideo).
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
                NativePlayerConfig.logW(
                    SUBTAG,
                    "MPD falló (${info.errorCode} HTTP=${info.httpStatus}); probando preset MPD #${mpdHeaderPresetIndex + 1}"
                )
                emit("retrying", "reason" to "mpd_headers_preset", "preset" to (mpdHeaderPresetIndex + 1))
                loadSource(useProxy = triedProxy)
                return
            }
        }

        // 5. Formato inferido incorrecto → cascada de formatos (DASH → HLS → PROGRESSIVE/TS).
        if (!hasBeenReady && PlayerErrorMapper.isFormatMismatch(info) && formatIndex + 1 < formatCandidates.size) {
            formatIndex++
            if (channel != null) {
                currentChannel = channel.copy(headers = LinkedHashMap(initialHeaders))
            }
            NativePlayerConfig.logW(SUBTAG, "Formato no válido; probando siguiente formato: ${currentFormat.name}")
            emit("retrying", "reason" to "format_fallback", "format" to currentFormat.name)
            loadSource(useProxy = triedProxy)
            return
        }

        // 6. Widevine L1 con error de DRM o decoder → fallback a L3 o SurfaceView.
        val isWidevine = channel?.drmScheme == DrmScheme.WIDEVINE
        if (isWidevine && !forceL3 &&
            (PlayerErrorMapper.isDrmError(info) || info.errorCode == PlayerErrorMapper.ERROR_DECODER)
        ) {
            forceL3 = true
            NativePlayerConfig.logW(SUBTAG, "Widevine L1 falló (${info.errorCode}); reintentando en modo L3")
            emit("retrying", "reason" to "widevine_l3")
            loadSource(useProxy = triedProxy)
            return
        }

        // 7. Decoder error: bajar restricción de resolución y reintentar una vez.
        if (info.errorCode == PlayerErrorMapper.ERROR_DECODER && !decoderRetried) {
            decoderRetried = true
            allowChunklessHls = false
            trackSelector.parameters = trackSelector.parameters.buildUpon()
                .setMaxVideoSize(1280, 720)
                .build()
            NativePlayerConfig.logW(SUBTAG, "Error de decoder; bajando resolución máxima a 720p y reintentando")
            emit("retrying", "reason" to "decoder_downscale")
            loadSource(useProxy = triedProxy)
            return
        }

        // 8. Si el canal tiene configurado un Proxy (Cloudflare Worker) y falló por HTTP/Red, probar vía Proxy.
        val hasProxyAvailable = !channel?.proxyUrl.isNullOrBlank() ||
            !NativePlayerConfig.defaultCloudflareWorkerUrl.isNullOrBlank()
        if (!triedProxy && hasProxyAvailable &&
            (info.errorCode == PlayerErrorMapper.ERROR_HTTP || info.errorCode == PlayerErrorMapper.ERROR_NETWORK)
        ) {
            triedProxy = true
            NativePlayerConfig.logW(SUBTAG, "Fallo directo (${info.errorCode}); reintentando a través de Cloudflare Worker Proxy")
            emit("retrying", "reason" to "cloudflare_proxy")
            loadSource(useProxy = true)
            return
        }

        // 9. Red transitoria → backoff exponencial (500ms, 1000ms, 2000ms).
        if (PlayerErrorMapper.isTransientNetwork(info) && networkRetries < NativePlayerConfig.MAX_NETWORK_RETRIES) {
            val delay = (NativePlayerConfig.BASE_RETRY_DELAY_MS shl networkRetries)
                .coerceAtMost(NativePlayerConfig.MAX_RETRY_DELAY_MS)
            networkRetries++
            NativePlayerConfig.logW(
                SUBTAG,
                "Error de red transitorio; reintento $networkRetries/${NativePlayerConfig.MAX_NETWORK_RETRIES} en ${delay}ms"
            )
            emit("retrying", "reason" to "network_backoff", "attempt" to networkRetries, "delayMs" to delay)
            mainHandler.removeCallbacks(retryRunnable)
            mainHandler.postDelayed(retryRunnable, delay)
            return
        }

        // 10. Error definitivo en esta fuente → emitir a Flutter (incluyendo flag tokenExpired si es 401/403/410)
        emitError(info)
    }

    /**
     * Verifica dos tipos de congelamiento en tiempo real:
     *   A) Buffering prolongado (`STATE_BUFFERING` > 9s).
     *   B) Stream congelado en `STATE_READY` (`isPlaying == true`, pero `currentPosition` no se mueve por > 6.5s).
     */
    private fun checkStallAndFrozen(currentPosMs: Long) {
        val now = SystemClock.elapsedRealtime()

        // Caso A: Stall en STATE_BUFFERING
        if (player.playbackState == Player.STATE_BUFFERING && player.playWhenReady && hasBeenReady) {
            if (bufferingSince == 0L) bufferingSince = now
            if (now - bufferingSince > NativePlayerConfig.STALL_BUFFERING_TIMEOUT_MS) {
                bufferingSince = 0L
                onStallOrFrozenDetected("buffering_stall")
            }
            return
        } else {
            bufferingSince = 0L
        }

        // Caso B: Stream congelado en STATE_READY (reloj clavado aunque dice estar reproduciendo)
        if (player.playbackState == Player.STATE_READY && player.isPlaying && firstFrameRendered) {
            if (currentPosMs != lastObservedPositionMs) {
                lastObservedPositionMs = currentPosMs
                lastPositionAdvanceRealtime = now
            } else if (lastPositionAdvanceRealtime > 0L &&
                now - lastPositionAdvanceRealtime > NativePlayerConfig.FROZEN_STREAM_TIMEOUT_MS
            ) {
                lastPositionAdvanceRealtime = now
                onStallOrFrozenDetected("frozen_position")
            }
        } else {
            lastPositionAdvanceRealtime = now
        }
    }

    private fun onStallOrFrozenDetected(reason: String) {
        if (networkRetries < NativePlayerConfig.MAX_NETWORK_RETRIES) {
            networkRetries++
            NativePlayerConfig.logW(SUBTAG, "Stream congelado ($reason); recuperando al borde en vivo (#$networkRetries)")
            emit("retrying", "reason" to reason, "attempt" to networkRetries)
            player.stop()
            recoverInPlace()
        } else {
            emitError(
                PlayerErrorInfo(
                    PlayerErrorMapper.ERROR_NETWORK,
                    "Stream congelado sin avance ($reason)"
                )
            )
        }
    }

    private fun cancelScheduled() {
        mainHandler.removeCallbacks(retryRunnable)
        mainHandler.removeCallbacks(tickRunnable)
        mainHandler.removeCallbacks(audioWithoutVideoRunnable)
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
            emitState()
            when (state) {
                Player.STATE_READY -> {
                    networkRetries = 0
                    bufferingSince = 0L
                    hasBeenReady = true
                    lastPositionAdvanceRealtime = SystemClock.elapsedRealtime()
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

                    // Si aún no se renderizó el primer frame de video, armar el watchdog de "solo audio"
                    if (!firstFrameRendered) {
                        mainHandler.removeCallbacks(audioWithoutVideoRunnable)
                        mainHandler.postDelayed(
                            audioWithoutVideoRunnable,
                            NativePlayerConfig.AUDIO_WITHOUT_VIDEO_TIMEOUT_MS
                        )
                    }
                }
                Player.STATE_BUFFERING -> startTicker()
                Player.STATE_ENDED -> {
                    mainHandler.removeCallbacks(tickRunnable)
                    mainHandler.removeCallbacks(audioWithoutVideoRunnable)
                    if (isLive && networkRetries < NativePlayerConfig.MAX_NETWORK_RETRIES) {
                        networkRetries++
                        recoverInPlace()
                    } else {
                        emit("ended")
                    }
                }
                Player.STATE_IDLE -> {
                    mainHandler.removeCallbacks(tickRunnable)
                    mainHandler.removeCallbacks(audioWithoutVideoRunnable)
                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            if (isPlaying) {
                lastPositionAdvanceRealtime = SystemClock.elapsedRealtime()
            }
            emitState()
        }

        override fun onPlayerError(error: PlaybackException) {
            mainHandler.removeCallbacks(audioWithoutVideoRunnable)
            handleError(error)
        }

        override fun onRenderedFirstFrame() {
            firstFrameRendered = true
            hasBeenReady = true
            audioOnlyRecoveryStep = 0
            mainHandler.removeCallbacks(audioWithoutVideoRunnable)

            // Liberar el límite de bitrate inicial para permitir subida progresiva ABR a HD/FHD
            applySteadyStateQualityConstraints()

            NativePlayerConfig.logI(
                SUBTAG,
                "Primer frame renderizado (${player.videoSize.width}x${player.videoSize.height})"
            )
            emit("firstFrame")
        }

        override fun onVideoSizeChanged(videoSize: VideoSize) {
            if (videoSize.width == 0 || videoSize.height == 0) return
            emit(
                "videoSize",
                "videoWidth" to videoSize.width,
                "videoHeight" to videoSize.height,
                "pixelRatio" to videoSize.pixelWidthHeightRatio.toDouble()
            )
        }

        override fun onTracksChanged(tracks: Tracks) {
            emitTracks(tracks)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Monitor Nativo de Conectividad (Wi-Fi vs Datos Móviles + Reconexión)
    // ─────────────────────────────────────────────────────────────────────────

    private fun registerNetworkMonitor() {
        runCatching {
            val cm = appContext.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return
            cm.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    mainHandler.post {
                        if (hadNetworkLoss && currentChannel != null) {
                            hadNetworkLoss = false
                            NativePlayerConfig.logI(SUBTAG, "Red restaurada → reconectando al borde en vivo")
                            networkRetries = 0
                            emit("retrying", "reason" to "network_restored")
                            recoverInPlace()
                        }
                    }
                }

                override fun onLost(network: Network) {
                    mainHandler.post {
                        hadNetworkLoss = true
                        NativePlayerConfig.logW(SUBTAG, "Pérdida de red detectada")
                    }
                }

                override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                    val cellular = capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) &&
                        !capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
                    mainHandler.post {
                        if (cellular != isCellularNetwork) {
                            isCellularNetwork = cellular
                            NativePlayerConfig.logI(
                                SUBTAG,
                                "Cambio de transporte de red (cellular=$isCellularNetwork)"
                            )
                            if (firstFrameRendered) {
                                applySteadyStateQualityConstraints()
                            }
                            emit("networkTypeChanged", "isCellular" to isCellularNetwork)
                        }
                    }
                }
            })
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Emisión de Eventos a Flutter
    // ─────────────────────────────────────────────────────────────────────────

    private fun emitState() {
        val stateStr = when (player.playbackState) {
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> "ready"
            Player.STATE_ENDED -> "ended"
            else -> "idle"
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
            "tokenExpired" to PlayerErrorMapper.isTokenOrAccessError(info),
            "isAudioOnly" to (info.errorCode == PlayerErrorMapper.ERROR_AUDIO_ONLY),
            "isFatal" to true
        )
    }

    private fun emitTracks(tracks: Tracks) {
        val video = mutableListOf<Map<String, Any?>>()
        val audio = mutableListOf<Map<String, Any?>>()
        val text = mutableListOf<Map<String, Any?>>()
        var hasVideoGroup = false
        var hasSupportedVideo = false

        tracks.groups.forEachIndexed { groupIdx, group ->
            if (group.type == C.TRACK_TYPE_VIDEO) hasVideoGroup = true
            for (trackIdx in 0 until group.length) {
                val f: Format = group.getTrackFormat(trackIdx)
                val supported = group.isTrackSupported(trackIdx, /* allowExceedsCapabilities = */ false)
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
                    C.TRACK_TYPE_TEXT -> text.add(entry)
                }
            }
        }

        hasVideoTrackGroup = hasVideoGroup
        val videoUnsupported = hasVideoGroup && !hasSupportedVideo

        emit(
            "tracksChanged",
            "videoTracks" to video,
            "audioTracks" to audio,
            "textTracks" to text,
            "videoUnsupported" to videoUnsupported
        )

        // Si el manifiesto trae pistas de video pero ninguna es soportada por el hardware,
        // activar el mecanismo de recuperación de "solo audio sin video".
        if (videoUnsupported && !firstFrameRendered) {
            mainHandler.removeCallbacks(audioWithoutVideoRunnable)
            mainHandler.postDelayed(audioWithoutVideoRunnable, 800L)
        }
    }

    private fun emit(event: String, vararg pairs: Pair<String, Any?>) {
        val sink = eventListener ?: return
        val data = HashMap<String, Any?>(pairs.size + 2)
        data["event"] = event
        data["sessionId"] = sessionId
        pairs.forEach { data[it.first] = it.second }
        if (Looper.myLooper() == Looper.getMainLooper()) {
            sink(data)
        } else {
            mainHandler.post { eventListener?.invoke(data) }
        }
    }

    init {
        player.addListener(playerListener)
        registerNetworkMonitor()
    }
}
