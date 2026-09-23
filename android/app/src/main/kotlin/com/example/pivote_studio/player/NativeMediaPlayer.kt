package com.example.pivote_studio.player

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import com.example.pivote_studio.data.StreamChannel

/**
 * Interfaz de eventos del reproductor nativo.
 */
interface NativePlayerListener {
    fun onReady()
    fun onBuffering()
    fun onPlaying()
    fun onPaused()
    fun onEnded()
    fun onError(errorInfo: PlayerErrorInfo)
    fun onTracksChanged(tracks: Tracks)
}

/**
 * Motor central de reproducción nativa basado en Media3 ExoPlayer.
 * Maneja el ciclo de vida, buffers optimizados para TV/deportes en vivo,
 * recuperación ante fallos de red con backoff exponencial y desvinculación limpia de memoria.
 */
@OptIn(UnstableApi::class)
class NativeMediaPlayer(private val context: Context) {

    companion object {
        private const val TAG = "NativeMediaPlayer"
        private const val MAX_RETRY_ATTEMPTS = 3
        private const val BASE_RETRY_DELAY_MS = 1_000L
    }

    private var exoPlayer: ExoPlayer? = null
    private var currentChannel: StreamChannel? = null
    private var retryCount = 0
    private var isReleased = false
    private var isFullscreen = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private val retryRunnable = Runnable { retryPlayback() }

    var listener: NativePlayerListener? = null

    val player: ExoPlayer?
        get() = exoPlayer

    val isPlaying: Boolean
        get() = exoPlayer?.isPlaying == true

    val isBuffering: Boolean
        get() = exoPlayer?.playbackState == Player.STATE_BUFFERING

    val isLive: Boolean
        get() = exoPlayer?.isCurrentMediaItemLive == true || exoPlayer?.isCurrentMediaItemDynamic == true

    val currentPosition: Long
        get() = exoPlayer?.currentPosition ?: 0L

    val duration: Long
        get() {
            val d = exoPlayer?.duration ?: C.TIME_UNSET
            return if (d == C.TIME_UNSET || isLive) -1L else d
        }

    val volume: Float
        get() = exoPlayer?.volume ?: 1f

    /**
     * Prepara y comienza la reproducción del canal suministrado.
     */
    fun prepare(channel: StreamChannel) {
        if (isReleased) return

        mainHandler.removeCallbacks(retryRunnable)
        currentChannel = channel
        retryCount = 0

        try {
            ensurePlayerInitialized()
            val mediaSource = StreamMediaSourceFactory.createMediaSource(channel)

            exoPlayer?.let { p ->
                p.stop()
                p.clearMediaItems()
                p.setMediaSource(mediaSource)
                p.playWhenReady = true
                p.prepare()
            }
        } catch (e: Throwable) {
            val errorInfo = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(channel, errorInfo)
            listener?.onError(errorInfo)
        }
    }

    private fun ensurePlayerInitialized() {
        if (exoPlayer != null) return

        // Buffer balanceado para TV y deportes en vivo (sin buffering excesivo ni microcortes)
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs */ 8_000,
                /* maxBufferMs */ 35_000,
                /* bufferForPlaybackMs */ 1_000,
                /* bufferForPlaybackAfterRebufferMs */ 2_000
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(/* backBufferDurationMs */ 10_000, /* retainBackBufferFromKeyframe */ false)
            .build()

        val playerInstance = ExoPlayer.Builder(context)
            .setLoadControl(loadControl)
            .build()

        playerInstance.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                if (isReleased) return
                when (state) {
                    Player.STATE_BUFFERING -> listener?.onBuffering()
                    Player.STATE_READY -> {
                        retryCount = 0
                        listener?.onReady()
                    }
                    Player.STATE_ENDED -> listener?.onEnded()
                    Player.STATE_IDLE -> { /* idle */ }
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isReleased) return
                if (isPlaying) {
                    listener?.onPlaying()
                } else if (exoPlayer?.playbackState == Player.STATE_READY) {
                    listener?.onPaused()
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                if (isReleased) return

                val errorInfo = PlayerErrorMapper.map(error)
                PlayerErrorMapper.logError(currentChannel, errorInfo)

                // Backoff controlado para errores de red o temporales
                if (shouldAttemptRetry(errorInfo) && retryCount < MAX_RETRY_ATTEMPTS) {
                    retryCount++
                    val delay = BASE_RETRY_DELAY_MS * (1 shl (retryCount - 1))
                    Log.w(TAG, "Reintentando reproducción en ${delay}ms (Intento $retryCount de $MAX_RETRY_ATTEMPTS)...")
                    listener?.onBuffering()
                    mainHandler.postDelayed(retryRunnable, delay)
                } else {
                    listener?.onError(errorInfo)
                }
            }

            override fun onTracksChanged(tracks: Tracks) {
                if (isReleased) return
                listener?.onTracksChanged(tracks)
            }
        })

        exoPlayer = playerInstance
    }

    private fun shouldAttemptRetry(error: PlayerErrorInfo): Boolean {
        return error.errorCode == PlayerErrorMapper.ERROR_NETWORK ||
               error.errorCode == PlayerErrorMapper.ERROR_HTTP ||
               error.errorCode == PlayerErrorMapper.ERROR_MPD_LOAD
    }

    private fun retryPlayback() {
        val ch = currentChannel ?: return
        if (isReleased) return

        Log.d(TAG, "Ejecutando reintento de reproducción...")
        try {
            val mediaSource = StreamMediaSourceFactory.createMediaSource(ch)
            exoPlayer?.let { p ->
                p.setMediaSource(mediaSource)
                p.prepare()
                p.playWhenReady = true
            }
        } catch (e: Throwable) {
            val err = PlayerErrorMapper.map(e)
            PlayerErrorMapper.logError(ch, err)
            listener?.onError(err)
        }
    }

    fun play() {
        if (isReleased) return
        exoPlayer?.play()
    }

    fun pause() {
        if (isReleased) return
        exoPlayer?.pause()
    }

    fun stop() {
        mainHandler.removeCallbacks(retryRunnable)
        exoPlayer?.stop()
    }

    fun seekTo(positionMs: Long) {
        if (isReleased || isLive) return
        exoPlayer?.seekTo(positionMs)
    }

    fun setVolume(volume: Float) {
        if (isReleased) return
        exoPlayer?.volume = volume.coerceIn(0f, 1f)
    }

    fun setFullscreen(enabled: Boolean) {
        isFullscreen = enabled
    }

    fun isFullscreen(): Boolean = isFullscreen

    /**
     * Libera de forma completa y segura los recursos para evitar fugas de memoria.
     */
    fun release() {
        isReleased = true
        mainHandler.removeCallbacks(retryRunnable)
        listener = null
        exoPlayer?.let { p ->
            p.stop()
            p.clearMediaItems()
            p.release()
        }
        exoPlayer = null
        currentChannel = null
    }
}
