package com.example.pivote_studio

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * Professional ExoPlayer implementation for Flutter.
 * 
 * Features:
 * - DASH (MPD) with ClearKey DRM support
 * - HLS (M3U8) support
 * - Automatic DRM method fallback (hex -> UUID swap)
 * - Advanced buffering strategies
 * - Comprehensive error handling
 * - Stream health watchdog
 * - Quality track selection
 * 
 * @version 2.0
 * @author Pivote Studio Team
 */
@OptIn(UnstableApi::class)
class ExoPlayerView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler, Player.Listener {

    companion object {
        private const val TAG = "ExoPlayerView"
    }

    // UI
    private val playerView: PlayerView = PlayerView(context)
    
    // Player
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel: MethodChannel = MethodChannel(messenger, "exoplayer_$id")

    // State
    private var lastUrl: String? = null
    private var lastK1: String? = null
    private var lastK2: String? = null
    private var currentDrmMethod = DrmMethod.HEX
    private var retryCount = 0

    // Watchdog
    private val handler = Handler(Looper.getMainLooper())
    private var watchdogRunnable: Runnable? = null
    private var lastPosition: Long = 0
    private var stalledCount = 0

    // DRM Methods
    private enum class DrmMethod {
        HEX,        // Standard hex to base64
        UUID_SWAP   // Microsoft GUID byte swap
    }

    init {
        methodChannel.setMethodCallHandler(this)
        configurePlayerView()
        startWatchdog()
        Log.d(TAG, "ExoPlayerView initialized (id: $id)")
    }

    private fun configurePlayerView() {
        playerView.apply {
            useController = true
            controllerShowTimeoutMs = PlayerConfig.UI.CONTROLLER_TIMEOUT_MS
            controllerHideOnTouch = true
            setShowBuffering(PlayerView.SHOW_BUFFERING_ALWAYS)
        }
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "initialize" -> handleInitialize(call, result)
                "play" -> handlePlay(result)
                "pause" -> handlePause(result)
                "stop" -> handleStop(result)
                "dispose" -> handleDispose(result)
                "setVolume" -> handleSetVolume(call, result)
                "getPosition" -> handleGetPosition(result)
                "getDuration" -> handleGetDuration(result)
                "isPlaying" -> handleIsPlaying(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in method ${call.method}", e)
            result.error("EXCEPTION", e.message, e.stackTraceToString())
        }
    }

    private fun handleInitialize(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>("url")
        val k1 = call.argument<String>("k1")
        val k2 = call.argument<String>("k2")

        if (url == null) {
            result.error("INVALID_ARGUMENT", "URL is required", null)
            return
        }

        lastUrl = url
        lastK1 = k1
        lastK2 = k2
        currentDrmMethod = DrmMethod.HEX
        retryCount = 0

        initializePlayer(url, k1, k2, currentDrmMethod)
        result.success(true)
    }

    private fun handlePlay(result: MethodChannel.Result) {
        exoPlayer?.play()
        result.success(true)
    }

    private fun handlePause(result: MethodChannel.Result) {
        exoPlayer?.pause()
        result.success(true)
    }

    private fun handleStop(result: MethodChannel.Result) {
        exoPlayer?.stop()
        result.success(true)
    }

    private fun handleDispose(result: MethodChannel.Result) {
        disposePlayer()
        result.success(true)
    }

    private fun handleSetVolume(call: MethodCall, result: MethodChannel.Result) {
        val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
        exoPlayer?.volume = volume.coerceIn(0f, 1f)
        result.success(true)
    }

    private fun handleGetPosition(result: MethodChannel.Result) {
        result.success(exoPlayer?.currentPosition ?: 0L)
    }

    private fun handleGetDuration(result: MethodChannel.Result) {
        result.success(exoPlayer?.duration ?: 0L)
    }

    private fun handleIsPlaying(result: MethodChannel.Result) {
        result.success(exoPlayer?.isPlaying ?: false)
    }

    /**
     * Initializes the ExoPlayer with the given URL and optional DRM keys.
     */
    private fun initializePlayer(url: String, k1: String?, k2: String?, drmMethod: DrmMethod) {
        val hasDrm = k1 != null && k2 != null
        Log.d(TAG, "═══════════════════════════════════════")
        Log.d(TAG, "Initializing ExoPlayer")
        Log.d(TAG, "URL: $url")
        Log.d(TAG, "DRM: ${if (hasDrm) "Yes (Method: $drmMethod)" else "No"}")
        Log.d(TAG, "═══════════════════════════════════════")

        disposePlayer()

        try {
            // Track Selector with quality preferences
            val trackSelector = DefaultTrackSelector(context).apply {
                setParameters(
                    buildUponParameters()
                        .setMaxVideoSizeSd()
                        .setPreferredAudioLanguage("es") // Spanish preference
                )
            }

            // Load Control with professional buffering
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    PlayerConfig.Buffering.MIN_BUFFER_MS,
                    PlayerConfig.Buffering.MAX_BUFFER_MS,
                    PlayerConfig.Buffering.BUFFER_FOR_PLAYBACK_MS,
                    PlayerConfig.Buffering.BUFFER_FOR_REBUFFER_MS
                )
                .build()

            // Data Source Factory
            val dataSourceFactory = DefaultHttpDataSource.Factory()
                .setUserAgent(PlayerConfig.USER_AGENT)
                .setAllowCrossProtocolRedirects(PlayerConfig.Network.ALLOW_CROSS_PROTOCOL)
                .setConnectTimeoutMs(PlayerConfig.Network.CONNECT_TIMEOUT_MS)
                .setReadTimeoutMs(PlayerConfig.Network.READ_TIMEOUT_MS)

            // Media Source Factory
            val mediaSourceFactory = DefaultMediaSourceFactory(dataSourceFactory)

            // Configure DRM if needed
            if (hasDrm) {
                val drmSessionManager = createDrmSessionManager(k1!!, k2!!, drmMethod)
                mediaSourceFactory.setDrmSessionManagerProvider { drmSessionManager }
            }

            // Build ExoPlayer
            exoPlayer = ExoPlayer.Builder(context)
                .setTrackSelector(trackSelector)
                .setLoadControl(loadControl)
                .setMediaSourceFactory(mediaSourceFactory)
                .build()

            exoPlayer?.addListener(this)
            playerView.player = exoPlayer

            // Build and set media item
            val mediaItem = MediaItem.Builder()
                .setUri(Uri.parse(url))
                .build()

            exoPlayer?.setMediaItem(mediaItem)
            exoPlayer?.prepare()
            exoPlayer?.playWhenReady = true

            Log.d(TAG, "✅ ExoPlayer initialized successfully")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error initializing player", e)
            notifyError("Initialization Error: ${e.message}", "INIT_ERROR", e.cause?.message)
        }
    }

    /**
     * Creates a DRM session manager with ClearKey callback.
     */
    private fun createDrmSessionManager(
        k1: String,
        k2: String,
        method: DrmMethod
    ): DefaultDrmSessionManager {
        Log.d(TAG, "Creating DRM Session Manager")
        Log.d(TAG, "K1: ${k1.take(16)}...")
        Log.d(TAG, "K2: ${k2.take(16)}...")
        Log.d(TAG, "Method: $method")

        val useUuidSwap = method == DrmMethod.UUID_SWAP
        val drmCallback = ClearKeyDrmCallback(k1, k2, useUuidSwap)

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(C.CLEARKEY_UUID) { uuid ->
                androidx.media3.exoplayer.drm.FrameworkMediaDrm.newInstance(uuid)
            }
            .build(drmCallback)
    }

    // ═══════════════════════════════════════
    // Player Listeners
    // ═══════════════════════════════════════

    override fun onPlaybackStateChanged(playbackState: Int) {
        val stateString = when (playbackState) {
            Player.STATE_IDLE -> "idle"
            Player.STATE_BUFFERING -> "buffering"
            Player.STATE_READY -> "ready"
            Player.STATE_ENDED -> "ended"
            else -> "unknown"
        }

        Log.d(TAG, "📺 State: $stateString")
        methodChannel.invokeMethod("onStateChange", stateString)

        if (playbackState == Player.STATE_READY) {
            stalledCount = 0
            retryCount = 0
            Log.d(TAG, "✅ Playback ready (DRM method: $currentDrmMethod)")
        }
    }

    override fun onIsPlayingChanged(isPlaying: Boolean) {
        Log.d(TAG, "▶️ Playing: $isPlaying")
        methodChannel.invokeMethod("onPlayingChange", isPlaying)
    }

    override fun onPlayerError(error: PlaybackException) {
        Log.e(TAG, "❌ Player Error: ${error.errorCodeName}", error)
        Log.e(TAG, "Error Code: ${error.errorCode}")
        Log.e(TAG, "Message: ${error.message}")

        // DRM-specific error handling with automatic fallback
        if (isDrmError(error) && shouldRetryWithDifferentMethod()) {
            handleDrmErrorWithFallback()
            return
        }

        // Generic error retry
        if (retryCount < PlayerConfig.Retry.MAX_RETRY_ATTEMPTS) {
            retryCount++
            Log.w(TAG, "🔄 Retrying initialization (attempt $retryCount/${PlayerConfig.Retry.MAX_RETRY_ATTEMPTS})")
            
            handler.postDelayed({
                lastUrl?.let { url ->
                    initializePlayer(url, lastK1, lastK2, currentDrmMethod)
                }
            }, calculateBackoff(retryCount))
            return
        }

        // Max retries exceeded
        notifyError(
            error.message ?: "Unknown Error",
            error.errorCodeName,
            error.cause?.message
        )
    }

    private fun isDrmError(error: PlaybackException): Boolean {
        return error.errorCode == PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED ||
               error.errorCode == PlaybackException.ERROR_CODE_DRM_PROVISIONING_FAILED ||
               error.errorCode == PlaybackException.ERROR_CODE_DRM_DEVICE_REVOKED ||
               error.errorCode == PlaybackException.ERROR_CODE_DRM_SYSTEM_ERROR
    }

    private fun shouldRetryWithDifferentMethod(): Boolean {
        return PlayerConfig.Drm.ENABLE_UUID_SWAP_FALLBACK &&
               currentDrmMethod == DrmMethod.HEX &&
               lastK1 != null &&
               lastK2 != null
    }

    private fun handleDrmErrorWithFallback() {
        Log.w(TAG, "🔄 DRM Method HEX failed, trying UUID_SWAP...")
        currentDrmMethod = DrmMethod.UUID_SWAP
        retryCount = 0

        handler.post {
            lastUrl?.let { url ->
                initializePlayer(url, lastK1, lastK2, currentDrmMethod)
            }
        }
    }

    private fun calculateBackoff(attempt: Int): Long {
        val backoff = (PlayerConfig.Retry.INITIAL_BACKOFF_MS * 
                      Math.pow(PlayerConfig.Retry.BACKOFF_MULTIPLIER, (attempt - 1).toDouble())).toLong()
        return backoff.coerceAtMost(PlayerConfig.Retry.MAX_BACKOFF_MS)
    }

    private fun notifyError(message: String, code: String, cause: String? = null) {
        methodChannel.invokeMethod("onError", mapOf(
            "message" to message,
            "code" to code,
            "cause" to (cause ?: "")
        ))
    }

    // ═══════════════════════════════════════
    // Watchdog - Stream Health Monitoring
    // ═══════════════════════════════════════

    private fun startWatchdog() {
        stopWatchdog()
        watchdogRunnable = object : Runnable {
            override fun run() {
                checkPlaybackProgress()
                handler.postDelayed(this, PlayerConfig.Watchdog.CHECK_INTERVAL_MS)
            }
        }
        handler.postDelayed(watchdogRunnable!!, PlayerConfig.Watchdog.CHECK_INTERVAL_MS)
        Log.d(TAG, "🐕 Watchdog started")
    }

    private fun stopWatchdog() {
        watchdogRunnable?.let { 
            handler.removeCallbacks(it)
            Log.d(TAG, "🐕 Watchdog stopped")
        }
        watchdogRunnable = null
    }

    private fun checkPlaybackProgress() {
        val player = exoPlayer ?: return
        
        if (player.isPlaying) {
            val currentPos = player.currentPosition
            
            if (currentPos == lastPosition && currentPos > 0) {
                stalledCount++
                Log.w(TAG, "⚠️ Watchdog: Stream stalled ($stalledCount/${PlayerConfig.Watchdog.STALLED_THRESHOLD})")
                
                if (stalledCount >= PlayerConfig.Watchdog.STALLED_THRESHOLD) {
                    Log.e(TAG, "🚨 Watchdog: Stream is stuck!")
                    methodChannel.invokeMethod("onStreamStalled", null)
                    stalledCount = 0
                }
            } else {
                if (stalledCount > 0) {
                    Log.d(TAG, "✅ Watchdog: Stream recovered")
                }
                stalledCount = 0
                lastPosition = currentPos
            }
        }
    }

    // ═══════════════════════════════════════
    // Lifecycle Management
    // ═══════════════════════════════════════

    private fun disposePlayer() {
        Log.d(TAG, "🗑️ Disposing player")
        exoPlayer?.release()
        exoPlayer = null
        stalledCount = 0
        lastPosition = 0
    }

    override fun dispose() {
        Log.d(TAG, "🗑️ Disposing ExoPlayerView")
        stopWatchdog()
        disposePlayer()
    }
}
