package com.example.pivote_studio

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.player.NativeMediaPlayer
import com.example.pivote_studio.player.NativePlayerListener
import com.example.pivote_studio.player.PlayerErrorInfo
import com.example.pivote_studio.ui.NativePlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

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
// ExoPlayer PlatformView — Native Media3 MPEG-DASH / ClearKey Player
// ════════════════════════════════════════════════════════════════════════════

@OptIn(UnstableApi::class)
class ExoPlayerPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler, NativePlayerListener {

    private val methodChannel: MethodChannel =
        MethodChannel(messenger, "pivote/exoplayer_$viewId")
    private val eventChannel: EventChannel =
        EventChannel(messenger, "pivote/exoplayer_events_$viewId")

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val nativeMediaPlayer: NativeMediaPlayer = NativeMediaPlayer(context)
    private val playerView: NativePlayerView = NativePlayerView(context)

    private var isDisposed = false

    init {
        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        playerView.attachPlayer(nativeMediaPlayer, this)

        // Inicializar si se recibieron parámetros en la creación
        if (creationParams != null) {
            val channel = StreamChannel.fromMap(creationParams)
            if (channel.originalUrl.isNotBlank()) {
                initializePlayer(channel)
            }
        }
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                val channel = StreamChannel.fromMap(args)
                initializePlayer(channel)
                result.success(true)
            }
            "play" -> {
                nativeMediaPlayer.play()
                result.success(true)
            }
            "pause" -> {
                nativeMediaPlayer.pause()
                result.success(true)
            }
            "setVolume" -> {
                val volume = (call.argument<Double>("volume") ?: 1.0).toFloat()
                nativeMediaPlayer.setVolume(volume)
                result.success(true)
            }
            "setMuted" -> {
                val muted = call.argument<Boolean>("muted") ?: false
                nativeMediaPlayer.setVolume(if (muted) 0f else 1f)
                result.success(true)
            }
            "seekTo" -> {
                val pos = (call.argument<Number>("position") ?: 0).toLong()
                nativeMediaPlayer.seekTo(pos)
                result.success(true)
            }
            "getState" -> {
                result.success(getPlayerState())
            }
            "dispose" -> {
                dispose()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun initializePlayer(channel: StreamChannel) {
        if (isDisposed) return
        playerView.bindChannel(channel)
        sendEvent("initializing")
        nativeMediaPlayer.prepare(channel)
    }

    // ── Callbacks de NativePlayerListener ──────────────────────────────────────

    override fun onReady() {
        sendEvent("ready")
    }

    override fun onBuffering() {
        sendEvent("buffering")
    }

    override fun onPlaying() {
        sendEvent("playing")
    }

    override fun onPaused() {
        sendEvent("paused")
    }

    override fun onEnded() {
        sendEvent("ended")
    }

    override fun onError(errorInfo: PlayerErrorInfo) {
        sendEvent("error", mapOf(
            "code" to errorInfo.errorCode,
            "message" to errorInfo.technicalMessage,
            "type" to errorInfo.errorCode
        ))
    }

    override fun onTracksChanged(tracks: Tracks) {
        sendEvent("tracksChanged")
    }

    // ── Helper de Eventos hacia Flutter ───────────────────────────────────────

    private fun sendEvent(type: String, extra: Map<String, Any>? = null) {
        mainHandler.post {
            if (isDisposed || eventSink == null) return@post
            val event = mutableMapOf<String, Any>("type" to type)
            if (extra != null) event.putAll(extra)

            event["isPlaying"] = nativeMediaPlayer.isPlaying
            event["isBuffering"] = nativeMediaPlayer.isBuffering
            event["volume"] = nativeMediaPlayer.volume.toDouble()
            event["currentPosition"] = nativeMediaPlayer.currentPosition
            event["duration"] = nativeMediaPlayer.duration
            event["isLive"] = nativeMediaPlayer.isLive

            eventSink?.success(event)
        }
    }

    private fun getPlayerState(): Map<String, Any> {
        return mapOf(
            "status" to when {
                nativeMediaPlayer.isBuffering -> "buffering"
                nativeMediaPlayer.isPlaying -> "playing"
                else -> "paused"
            },
            "isPlaying" to nativeMediaPlayer.isPlaying,
            "isBuffering" to nativeMediaPlayer.isBuffering,
            "volume" to nativeMediaPlayer.volume.toDouble(),
            "currentPosition" to nativeMediaPlayer.currentPosition,
            "duration" to nativeMediaPlayer.duration,
            "isLive" to nativeMediaPlayer.isLive
        )
    }

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        methodChannel.setMethodCallHandler(null)
        eventSink = null
        playerView.detachPlayer()
        nativeMediaPlayer.release()
    }
}
