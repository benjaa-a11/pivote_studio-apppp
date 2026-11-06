package com.example.pivote_studio

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.player.NativeMediaPlayer
import com.example.pivote_studio.ui.NativePlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

// ─────────────────────────────────────────────────────────────────────────────
// Factory
// ─────────────────────────────────────────────────────────────────────────────

class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        ExoPlayerPlatformView(context, viewId, messenger, args as? Map<*, *>)
}

// ─────────────────────────────────────────────────────────────────────────────
// PlatformView
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Vista nativa ExoPlayer expuesta a Flutter a través de PlatformView.
 *
 * Canales (aislados por viewId):
 *   MethodChannel  pivote/player_methods_$viewId  → comandos Flutter → Android
 *   EventChannel   pivote/player_events_$viewId   → estado Android  → Flutter
 */
@OptIn(UnstableApi::class)
class ExoPlayerPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val methodChannel = MethodChannel(messenger, "pivote/player_methods_$viewId")
    private val eventChannel  = EventChannel(messenger, "pivote/player_events_$viewId")

    private var eventSink: EventChannel.EventSink? = null
    private val pendingEvents = mutableListOf<Map<String, Any?>>()
    private val mainHandler   = Handler(Looper.getMainLooper())

    private val useTexture = (creationParams?.get("useTextureView") as? Boolean) ?: true
    private val mediaPlayer = NativeMediaPlayer(context).apply {
        usesTextureSurface = useTexture
    }
    private val playerView = NativePlayerView(context, useTextureView = useTexture)

    private var isDisposed = false

    init {
        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                if (events != null) {
                    // Vaciar eventos encolados antes de que Flutter terminara de suscribirse
                    if (pendingEvents.isNotEmpty()) {
                        val copy = ArrayList(pendingEvents)
                        pendingEvents.clear()
                        copy.forEach { events.success(it) }
                    }
                    // Sincronizar estado actual del player
                    mediaPlayer.syncStateToFlutter()
                }
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Vinculamos el player a la vista UI
        playerView.attachPlayer(mediaPlayer)

        // Escuchamos todos los eventos del mediaPlayer para retransmitirlos a Flutter
        mediaPlayer.eventListener = { eventData ->
            emit(eventData)
        }

        // Preparar con parámetros de creación si vienen dados
        if (creationParams != null) {
            val ch = StreamChannel.fromMap(creationParams)
            if (ch.originalUrl.isNotBlank()) {
                mediaPlayer.prepare(ch)
            }
        }
    }

    override fun getView(): View = playerView

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        pendingEvents.clear()
        mediaPlayer.eventListener = null
        playerView.detachPlayer()
        mediaPlayer.release()
        methodChannel.setMethodCallHandler(null)
        eventSink = null
    }

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isDisposed) {
            result.error("DISPOSED", "El reproductor ya fue liberado", null)
            return
        }

        when (call.method) {
            "prepare" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                val ch   = StreamChannel.fromMap(args)
                pendingEvents.clear()
                mediaPlayer.prepare(ch)
                result.success(null)
            }

            "play"  -> { mediaPlayer.play(); result.success(null) }
            "pause" -> { mediaPlayer.pause(); result.success(null) }
            "stop"  -> { mediaPlayer.stop(); result.success(null) }

            "seekTo" -> {
                val ms = (call.argument<Any>("positionMs") as? Number)?.toLong() ?: 0L
                mediaPlayer.seekTo(ms)
                result.success(null)
            }

            "seekToLiveEdge" -> {
                mediaPlayer.seekToLiveEdge()
                result.success(null)
            }

            "setVolume" -> {
                val v = (call.argument<Any>("volume") as? Number)?.toFloat() ?: 1f
                mediaPlayer.setVolume(v)
                result.success(null)
            }

            "setPlaybackSpeed" -> {
                val s = (call.argument<Any>("speed") as? Number)?.toFloat() ?: 1f
                mediaPlayer.setPlaybackSpeed(s)
                result.success(null)
            }

            "setResizeMode" -> {
                val mode = call.argument<String>("mode")
                playerView.setResizeMode(mode)
                result.success(null)
            }

            "setTrack" -> {
                val typeStr  = call.argument<String>("trackType") ?: "video"
                val groupIdx = (call.argument<Any>("groupIndex")  as? Number)?.toInt() ?: -1
                val trackIdx = (call.argument<Any>("trackIndex")  as? Number)?.toInt() ?: -1
                val trackType = when (typeStr.lowercase()) {
                    "audio" -> C.TRACK_TYPE_AUDIO
                    "text"  -> C.TRACK_TYPE_TEXT
                    else    -> C.TRACK_TYPE_VIDEO
                }
                mediaPlayer.setTrack(trackType, groupIdx, trackIdx)
                result.success(null)
            }

            "setPreferredVideoQuality" -> {
                val maxH = (call.argument<Any>("maxHeight")  as? Number)?.toInt() ?: -1
                val maxB = (call.argument<Any>("maxBitrate") as? Number)?.toInt() ?: -1
                mediaPlayer.setPreferredVideoQuality(maxH, maxB)
                result.success(null)
            }

            "release" -> {
                pendingEvents.clear()
                playerView.detachPlayer()
                mediaPlayer.release()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun emit(data: Map<String, Any?>) {
        mainHandler.post {
            if (isDisposed) return@post
            val sink = eventSink
            if (sink != null) {
                sink.success(data)
            } else {
                // Evitar crecimiento ilimitado si aún no hay suscriptor
                if (pendingEvents.size < 30) {
                    pendingEvents.add(data)
                }
            }
        }
    }
}
