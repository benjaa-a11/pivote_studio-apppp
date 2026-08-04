package com.example.pivote_studio

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.common.util.Util
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec

// ════════════════════════════════════════════════════════════════════════════
// ExoPlayer PlatformView Factory
// ════════════════════════════════════════════════════════════════════════════

class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ExoPlayerPlatformView(context, viewId, messenger, args as? Map<*, *>)
    }
}

// ════════════════════════════════════════════════════════════════════════════
// ExoPlayer PlatformView — Native DASH/MPD + ClearKey DRM
// ════════════════════════════════════════════════════════════════════════════

@UnstableApi
class ExoPlayerPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val methodChannel: MethodChannel =
        MethodChannel(messenger, "pivote/exoplayer_$viewId")
    private val eventChannel: EventChannel =
        EventChannel(messenger, "pivote/exoplayer_events_$viewId")

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // ── Views ──
    private val container: FrameLayout = FrameLayout(context)
    private val playerView: PlayerView = PlayerView(context).apply {
        useController = false // Flutter handles controls
        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        setShutterBackgroundColor(0xFF000000.toInt())
    }

    // ── Player ──
    private var player: ExoPlayer? = null
    private var isDisposed = false

    // ── User Agent ──
    private val userAgent = "Mozilla/5.0 (Linux; Android 14; Pixel 8) " +
            "AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/124.0.0.0 Mobile Safari/537.36"

    init {
        container.addView(playerView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Auto-initialize if creation params provided
        if (creationParams != null) {
            val url = creationParams["url"] as? String
            val k1 = creationParams["k1"] as? String
            val k2 = creationParams["k2"] as? String
            @Suppress("UNCHECKED_CAST")
            val clearkeys = creationParams["clearkeys"] as? Map<String, String>
            if (url != null) {
                initializePlayer(url, k1, k2, clearkeys, null)
            }
        }
    }

    override fun getView(): View = container

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val url = call.argument<String>("url") ?: ""
                val k1 = call.argument<String>("k1")
                val k2 = call.argument<String>("k2")
                @Suppress("UNCHECKED_CAST")
                val clearkeys = call.argument<Map<String, String>>("clearkeys")
                val headers = call.argument<Map<String, String>>("headers")
                initializePlayer(url, k1, k2, clearkeys, headers)
                result.success(true)
            }
            "play" -> {
                player?.play()
                result.success(true)
            }
            "pause" -> {
                player?.pause()
                result.success(true)
            }
            "setVolume" -> {
                val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                player?.volume = volume
                result.success(true)
            }
            "setMuted" -> {
                val muted = call.argument<Boolean>("muted") ?: false
                player?.volume = if (muted) 0f else 1f
                result.success(true)
            }
            "getState" -> {
                result.success(getPlayerState())
            }
            "dispose" -> {
                releasePlayer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Player Initialization
    // ════════════════════════════════════════════════════════════════════════

    private fun initializePlayer(
        url: String,
        k1: String?,
        k2: String?,
        clearkeys: Map<String, String>?,
        headers: Map<String, String>?
    ) {
        releasePlayer()
        if (isDisposed) return

        // ── Load Control: aggressive buffering for live sports ──
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                /* minBufferMs */  8_000,
                /* maxBufferMs */ 50_000,
                /* bufferForPlayback */    500,
                /* bufferForPlaybackAfterRebuffer */ 2_000
            )
            .setPrioritizeTimeOverSizeThresholds(true)
            .setBackBuffer(30_000, true)
            .build()

        // ── HTTP DataSource with custom headers ──
        val httpFactory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(10_000)
            .setReadTimeoutMs(10_000)
            .setAllowCrossProtocolRedirects(true)

        if (headers != null && headers.isNotEmpty()) {
            httpFactory.setDefaultRequestProperties(headers)
        }

        // ── Build ExoPlayer ──
        val builder = ExoPlayer.Builder(context)
            .setLoadControl(loadControl)

        // ── ClearKey DRM (multi-key or legacy single-key) ──
        val hasMultiKey = clearkeys != null && clearkeys.isNotEmpty()
        val hasLegacyKey = !k1.isNullOrEmpty() && !k2.isNullOrEmpty()
        val hasDrm = hasMultiKey || hasLegacyKey

        if (hasDrm) {
            val clearKeyJson = if (hasMultiKey) {
                buildMultiClearKeyJson(clearkeys!!)
            } else {
                buildClearKeyJson(k1!!, k2!!)
            }
            val drmCallback = LocalMediaDrmCallback(clearKeyJson.toByteArray(Charsets.UTF_8))
            val drmSessionManager = DefaultDrmSessionManager.Builder()
                .setUuidAndExoMediaDrmProvider(C.CLEARKEY_UUID, androidx.media3.exoplayer.drm.FrameworkMediaDrm.DEFAULT_PROVIDER)
                .build(drmCallback)

            val dashFactory = DashMediaSource.Factory(httpFactory)
                .setDrmSessionManagerProvider { drmSessionManager }

            builder.setMediaSourceFactory(dashFactory)
        } else {
            val dashFactory = DashMediaSource.Factory(httpFactory)
            builder.setMediaSourceFactory(dashFactory)
        }

        val exoPlayer = builder.build()

        // ── Player Listener ──
        exoPlayer.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                if (isDisposed) return
                when (state) {
                    Player.STATE_BUFFERING -> sendEvent("buffering")
                    Player.STATE_READY -> sendEvent("ready")
                    Player.STATE_ENDED -> sendEvent("ended")
                    Player.STATE_IDLE -> sendEvent("idle")
                }
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                if (isDisposed) return
                sendEvent(if (isPlaying) "playing" else "paused")
            }

            override fun onPlayerError(error: PlaybackException) {
                if (isDisposed) return
                val errorMsg = error.message ?: "Unknown error"
                val errorCode = error.errorCode
                sendEvent("error", mapOf(
                    "code" to errorCode,
                    "message" to errorMsg,
                    "type" to getErrorType(error)
                ))
            }
        })

        // ── Set source and start ──
        val mediaItem = MediaItem.Builder()
            .setUri(Uri.parse(url))
            .setMimeType(androidx.media3.common.MimeTypes.APPLICATION_MPD)
            .build()

        exoPlayer.setMediaItem(mediaItem)
        exoPlayer.playWhenReady = true
        exoPlayer.prepare()

        player = exoPlayer
        playerView.player = exoPlayer

        sendEvent("initializing")
    }

    // ════════════════════════════════════════════════════════════════════════
    // ClearKey DRM JSON License
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Build ClearKey JSON with a SINGLE key pair (legacy k1/k2 format).
     */
    private fun buildClearKeyJson(kid: String, key: String): String {
        val kidB64 = hexToBase64Url(kid)
        val keyB64 = hexToBase64Url(key)
        return """{"keys":[{"kty":"oct","k":"$keyB64","kid":"$kidB64"}],"type":"temporary"}"""
    }

    /**
     * Build ClearKey JSON with MULTIPLE key pairs.
     * Input: Map<keyId(hex), key(hex)>  →  JSON {"keys":[...], "type":"temporary"}
     * Each entry becomes a separate object in the keys array.
     */
    private fun buildMultiClearKeyJson(keys: Map<String, String>): String {
        val keysArray = keys.entries.joinToString(",") { (kid, key) ->
            val kidB64 = hexToBase64Url(kid)
            val keyB64 = hexToBase64Url(key)
            """{"kty":"oct","k":"$keyB64","kid":"$kidB64"}"""
        }
        return """{"keys":[$keysArray],"type":"temporary"}"""
    }

    /**
     * Convert hex string to base64url (no padding, URL-safe).
     */
    private fun hexToBase64Url(hex: String): String {
        val bytes = hexToBytes(hex)
        return android.util.Base64.encodeToString(
            bytes,
            android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP
        )
    }

    private fun hexToBytes(hex: String): ByteArray {
        val cleanHex = hex.replace("-", "").replace(" ", "")
        return ByteArray(cleanHex.length / 2) { i ->
            cleanHex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Event & State Helpers
    // ════════════════════════════════════════════════════════════════════════

    private fun sendEvent(type: String, extra: Map<String, Any>? = null) {
        mainHandler.post {
            if (isDisposed || eventSink == null) return@post
            val event = mutableMapOf<String, Any>("type" to type)
            if (extra != null) event.putAll(extra)

            // Always include player state
            player?.let { p ->
                event["isPlaying"] = p.isPlaying
                event["isBuffering"] = p.playbackState == Player.STATE_BUFFERING
                event["volume"] = p.volume.toDouble()
                event["currentPosition"] = p.currentPosition
                event["duration"] = p.duration
                event["bufferedPosition"] = p.bufferedPosition
            }

            eventSink?.success(event)
        }
    }

    private fun getPlayerState(): Map<String, Any> {
        val p = player ?: return mapOf("status" to "idle")
        return mapOf(
            "status" to when (p.playbackState) {
                Player.STATE_BUFFERING -> "buffering"
                Player.STATE_READY -> if (p.isPlaying) "playing" else "paused"
                Player.STATE_ENDED -> "ended"
                else -> "idle"
            },
            "isPlaying" to p.isPlaying,
            "isBuffering" to (p.playbackState == Player.STATE_BUFFERING),
            "volume" to p.volume.toDouble(),
            "currentPosition" to p.currentPosition,
            "duration" to p.duration,
            "bufferedPosition" to p.bufferedPosition
        )
    }

    private fun getErrorType(error: PlaybackException): String {
        return when (error.errorCode) {
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED -> "network"
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT -> "timeout"
            PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS -> "http"
            PlaybackException.ERROR_CODE_DRM_SYSTEM_ERROR -> "drm"
            PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED -> "drm_license"
            PlaybackException.ERROR_CODE_DRM_PROVISIONING_FAILED -> "drm_provision"
            PlaybackException.ERROR_CODE_PARSING_MANIFEST_MALFORMED -> "manifest"
            else -> "unknown"
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Cleanup
    // ════════════════════════════════════════════════════════════════════════

    private fun releasePlayer() {
        player?.let { p ->
            p.stop()
            playerView.player = null
            p.release()
        }
        player = null
    }

    override fun dispose() {
        isDisposed = true
        methodChannel.setMethodCallHandler(null)
        releasePlayer()
    }
}
