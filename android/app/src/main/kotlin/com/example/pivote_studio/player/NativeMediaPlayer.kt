package com.example.pivote_studio.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.common.TrackGroup
import androidx.media3.common.TrackSelectionOverride
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import com.example.pivote_studio.data.StreamChannel

// ─────────────────────────────────────────────────────────────────────────────
// Listener contract
// ─────────────────────────────────────────────────────────────────────────────

interface NativePlayerListener {
    fun onReady(durationMs: Long, isLive: Boolean, videoWidth: Int, videoHeight: Int)
    fun onStateChanged(playbackState: Int, isPlaying: Boolean)
    fun onPosition(positionMs: Long, bufferedMs: Long)
    fun onTracksChanged(tracks: Tracks)
    fun onError(errorInfo: PlayerErrorInfo)
    fun onEnded()
}

// ─────────────────────────────────────────────────────────────────────────────
// NativeMediaPlayer
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Motor central de reproducción basado en Media3 ExoPlayer.
 *
 * Características:
 *   • Una sola instancia por pantalla — ciclo de vida estricto.
 *   • Soporta HLS (m3u8), DASH (mpd), HTTP progresivo (mp4, ts…).
 *   • DRM: ClearKey (W3C JSON local) y Widevine Modular (CENC / CBCS).
 *   • DefaultTrackSelector: selección dinámica de audio, subtítulos y calidad de video.
 *   • Headers HTTP personalizados por canal.
 *   • Reintento automático con backoff exponencial ante errores de red.
 *   • Emisión periódica de posición (1 s) para la barra de progreso.
 */
@OptIn(UnstableApi::class)
class NativeMediaPlayer(private val context: Context) {

    companion object {
        private const val TAG = "PivoteExoPlayer"
        private const val MAX_RETRIES        = 4
        private const val BASE_RETRY_MS      = 800L
        private const val POSITION_TICK_MS   = 1_000L
    }

    // ── Core ─────────────────────────────────────────────────────────────────
    private var exoPlayer: ExoPlayer? = null
    private var trackSelector: DefaultTrackSelector? = null

    // ── State ─────────────────────────────────────────────────────────────────
    private var currentChannel: StreamChannel? = null
    private var retryCount     = 0
    private var isReleased     = false

    // ── Scheduler ─────────────────────────────────────────────────────────────
    private val mainHandler      = Handler(Looper.getMainLooper())
    private val retryRunnable    = Runnable { retryPlayback() }
    private val positionRunnable = object : Runnable {
        override fun run() {
            if (!isReleased) {
                val p = exoPlayer ?: return
                listener?.onPosition(p.currentPosition, p.bufferedPosition)
                mainHandler.postDelayed(this, POSITION_TICK_MS)
            }
        }
    }

    var listener: NativePlayerListener? = null

    // ── Public read-only properties ──────────────────────────────────────────
    val player: ExoPlayer? get() = exoPlayer
    val isPlaying: Boolean  get() = exoPlayer?.isPlaying == true
    val isBuffering: Boolean get() = exoPlayer?.playbackState == Player.STATE_BUFFERING
    val isLive: Boolean get() = exoPlayer?.isCurrentMediaItemLive == true ||
                                exoPlayer?.isCurrentMediaItemDynamic == true
    val currentPosition: Long get() = exoPlayer?.currentPosition ?: 0L
    val duration: Long get() {
        val d = exoPlayer?.duration ?: C.TIME_UNSET
        return if (d == C.TIME_UNSET || isLive) -1L else d
    }
    val volume: Float get() = exoPlayer?.volume ?: 1f

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    fun prepare(channel: StreamChannel) {
        if (isReleased) return
        mainHandler.removeCallbacks(retryRunnable)
        currentChannel = channel
        retryCount = 0

        try {
            ensurePlayer()
            val source = StreamMediaSourceFactory.createMediaSource(channel)
            exoPlayer?.run {
                stop()
                clearMediaItems()
                setMediaSource(source)
                playWhenReady = true
                prepare()
            }
        } catch (e: Throwable) {
            val info = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(channel, info)
            listener?.onError(info)
        }
    }

    fun play()  { if (!isReleased) exoPlayer?.play() }
    fun pause() { if (!isReleased) exoPlayer?.pause() }

    fun stop() {
        mainHandler.removeCallbacks(retryRunnable)
        mainHandler.removeCallbacks(positionRunnable)
        exoPlayer?.stop()
    }

    fun seekTo(positionMs: Long) {
        if (isReleased || isLive) return
        exoPlayer?.seekTo(positionMs)
    }

    fun setVolume(v: Float) {
        if (isReleased) return
        exoPlayer?.volume = v.coerceIn(0f, 1f)
    }

    fun setPlaybackSpeed(speed: Float) {
        if (isReleased) return
        exoPlayer?.playbackParameters = PlaybackParameters(speed.coerceIn(0.25f, 2f))
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Track Selection
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Selecciona una pista concreta.
     *
     * @param trackType  C.TRACK_TYPE_VIDEO | C.TRACK_TYPE_AUDIO | C.TRACK_TYPE_TEXT
     * @param groupIndex índice del TrackGroup dentro de las pistas del tipo indicado
     * @param trackIndex índice del formato dentro del TrackGroup
     */
    fun setTrack(trackType: Int, groupIndex: Int, trackIndex: Int) {
        val ts = trackSelector ?: return
        val p  = exoPlayer ?: return

        val groups: List<Tracks.Group> = p.currentTracks.groups
            .filter { it.type == trackType }

        if (groupIndex < 0 || groupIndex >= groups.size) {
            Log.w(TAG, "setTrack: groupIndex $groupIndex fuera de rango (${groups.size} grupos)")
            return
        }

        val group: TrackGroup = groups[groupIndex].mediaTrackGroup
        if (trackIndex < 0 || trackIndex >= group.length) {
            Log.w(TAG, "setTrack: trackIndex $trackIndex fuera de rango (${group.length} tracks)")
            return
        }

        val override = TrackSelectionOverride(group, trackIndex)
        val params = ts.parameters.buildUpon()
            .setOverrideForType(override)
            .build()
        ts.parameters = params
    }

    /**
     * Fija un límite de resolución / bitrate de video, o pasa maxHeight = -1 para Automático.
     */
    fun setPreferredVideoQuality(maxHeight: Int, maxBitrate: Int) {
        val ts = trackSelector ?: return
        val params = ts.parameters.buildUpon()
            .apply {
                if (maxHeight <= 0) {
                    // Automático: limpia restricciones
                    setMaxVideoSize(Int.MAX_VALUE, Int.MAX_VALUE)
                    setMaxVideoBitrate(Int.MAX_VALUE)
                } else {
                    setMaxVideoSizeSd() // reset primero
                    setMaxVideoSize(Int.MAX_VALUE, maxHeight)
                    if (maxBitrate > 0) setMaxVideoBitrate(maxBitrate)
                }
            }
            .build()
        ts.parameters = params
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Release
    // ─────────────────────────────────────────────────────────────────────────

    fun release() {
        isReleased = true
        mainHandler.removeCallbacks(retryRunnable)
        mainHandler.removeCallbacks(positionRunnable)
        listener = null
        exoPlayer?.run {
            stop()
            clearMediaItems()
            release()
        }
        exoPlayer   = null
        trackSelector = null
        currentChannel = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Internal helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun ensurePlayer() {
        if (exoPlayer != null) return

        val ts = DefaultTrackSelector(context).apply {
            // Adaptativo por defecto; preferir calidad máxima disponible
            parameters = buildUponParameters()
                .setAllowVideoMixedMimeTypeAdaptiveness(true)
                .setAllowAudioMixedMimeTypeAdaptiveness(true)
                .build()
        }
        trackSelector = ts

        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs */                     8_000,
                /* maxBufferMs */                    35_000,
                /* bufferForPlaybackMs */              1_500,
                /* bufferForPlaybackAfterRebufferMs */ 3_000
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(10_000, false)
            .build()

        val p = ExoPlayer.Builder(context)
            .setTrackSelector(ts)
            .setLoadControl(loadControl)
            .build()

        p.addListener(object : Player.Listener {

            override fun onPlaybackStateChanged(state: Int) {
                if (isReleased) return
                val playing = p.isPlaying
                listener?.onStateChanged(state, playing)
                when (state) {
                    Player.STATE_READY -> {
                        retryCount = 0
                        mainHandler.post(positionRunnable)
                        listener?.onReady(
                            durationMs  = if (p.isCurrentMediaItemLive) -1L else p.duration.coerceAtLeast(0L),
                            isLive      = p.isCurrentMediaItemLive || p.isCurrentMediaItemDynamic,
                            videoWidth  = p.videoSize.width,
                            videoHeight = p.videoSize.height
                        )
                    }
                    Player.STATE_ENDED -> {
                        mainHandler.removeCallbacks(positionRunnable)
                        listener?.onEnded()
                    }
                    Player.STATE_IDLE -> mainHandler.removeCallbacks(positionRunnable)
                    else -> { /* BUFFERING — no action */ }
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isReleased) return
                listener?.onStateChanged(p.playbackState, isPlaying)
                if (!isPlaying) mainHandler.removeCallbacks(positionRunnable)
                else if (p.playbackState == Player.STATE_READY) mainHandler.post(positionRunnable)
            }

            override fun onPlayerError(error: PlaybackException) {
                if (isReleased) return
                val info = PlayerErrorMapper.map(error)
                PlayerErrorMapper.logError(currentChannel, info)

                if (shouldRetry(info) && retryCount < MAX_RETRIES) {
                    retryCount++
                    val delay = BASE_RETRY_MS * (1 shl (retryCount - 1))
                    Log.w(TAG, "Reintentando en ${delay}ms (intento $retryCount/$MAX_RETRIES)…")
                    mainHandler.postDelayed(retryRunnable, delay)
                } else {
                    listener?.onError(info)
                }
            }

            override fun onTracksChanged(tracks: Tracks) {
                if (isReleased) return
                listener?.onTracksChanged(tracks)
            }
        })

        exoPlayer = p
    }

    private fun shouldRetry(e: PlayerErrorInfo): Boolean =
        e.errorCode in setOf(
            PlayerErrorMapper.ERROR_NETWORK,
            PlayerErrorMapper.ERROR_HTTP,
            PlayerErrorMapper.ERROR_MPD_LOAD
        )

    private fun retryPlayback() {
        val ch = currentChannel ?: return
        if (isReleased) return
        Log.d(TAG, "Ejecutando reintento de reproducción…")
        try {
            val source = StreamMediaSourceFactory.createMediaSource(ch)
            exoPlayer?.run {
                setMediaSource(source)
                prepare()
                playWhenReady = true
            }
        } catch (e: Throwable) {
            val info = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(ch, info)
            listener?.onError(info)
        }
    }
}
