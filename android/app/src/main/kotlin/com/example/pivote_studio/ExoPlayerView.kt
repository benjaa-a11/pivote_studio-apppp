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
import com.example.pivote_studio.player.NativePlayerConfig
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

class ExoPlayerViewFactory(
    private val messenger: BinaryMessenger,
    private val pipController: (() -> Boolean)? = null
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        ExoPlayerPlatformView(context, viewId, messenger, args as? Map<*, *>, pipController)
}

// ─────────────────────────────────────────────────────────────────────────────
// PlatformView (Conectada al Singleton NativeMediaPlayer)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Vista nativa ExoPlayer expuesta a Flutter a través de PlatformView.
 *
 * ARQUITECTURA SINGLE-PLAYER:
 *   • Todas las vistas reutilizan la instancia única `NativeMediaPlayer.getInstance(context)`.
 *   • Al crearse una vista nueva o rotar, el `ExoPlayer` único se transfiere con
 *     `PlayerView.switchTargetView` sin recrear decodificadores ni duplicar audio.
 *   • Al hacer `dispose` de la vista, se desvincula la Surface y se detiene la reproducción
 *     solamente si esta vista sigue siendo la propietaria activa del motor.
 */
@OptIn(UnstableApi::class)
class ExoPlayerPlatformView(
    context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<*, *>?,
    private val pipController: (() -> Boolean)? = null
) : PlatformView, MethodChannel.MethodCallHandler {

    companion object {
        @Volatile
        private var activeOwnerViewId: Int = -1
    }

    private val methodChannel = MethodChannel(messenger, "pivote/player_methods_$viewId")
    private val eventChannel = EventChannel(messenger, "pivote/player_events_$viewId")

    private var eventSink: EventChannel.EventSink? = null
    private val pendingEvents = mutableListOf<Map<String, Any?>>()
    private val mainHandler = Handler(Looper.getMainLooper())

    private val useTexture = (creationParams?.get("useTextureView") as? Boolean) ?: true
    private val mediaPlayer = NativeMediaPlayer.getInstance(context)
    private val playerView = NativePlayerView(context, useTextureView = useTexture)

    private var isDisposed = false

    init {
        activeOwnerViewId = viewId
        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                if (events != null) {
                    if (pendingEvents.isNotEmpty()) {
                        val copy = ArrayList(pendingEvents)
                        pendingEvents.clear()
                        copy.forEach { events.success(it) }
                    }
                    mediaPlayer.syncStateToFlutter()
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Vincular el motor único a esta vista
        playerView.attachToEngine(mediaPlayer)

        // Suscribir los eventos del motor único hacia esta vista activa
        mediaPlayer.eventListener = { eventData ->
            emit(eventData)
        }

        // Preparar si se enviaron creationParams iniciales
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
        playerView.detachFromEngine()

        // Solo limpiar el listener y parar la reproducción si ninguna vista más nueva tomó el control
        if (activeOwnerViewId == viewId) {
            mediaPlayer.eventListener = null
            mediaPlayer.stop()
        }

        methodChannel.setMethodCallHandler(null)
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isDisposed) {
            result.error("DISPOSED", "La vista del reproductor ya fue liberada", null)
            return
        }

        // Asegurar que esta vista es la propietaria activa cuando recibe un comando
        activeOwnerViewId = viewId
        playerView.attachToEngine(mediaPlayer)
        mediaPlayer.eventListener = { eventData -> emit(eventData) }

        when (call.method) {
            "prepare" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                val ch = StreamChannel.fromMap(args)
                pendingEvents.clear()
                mediaPlayer.prepare(ch)
                result.success(null)
            }

            "preload" -> {
                val url = call.argument<String>("url") ?: ""
                @Suppress("UNCHECKED_CAST")
                val headers = (call.argument<Map<String, String>>("headers")) ?: emptyMap()
                mediaPlayer.preloadManifest(url, headers)
                result.success(null)
            }

            "setCloudflareProxy" -> {
                val workerUrl = call.argument<String>("workerUrl")
                NativePlayerConfig.defaultCloudflareWorkerUrl = workerUrl
                result.success(null)
            }

            "play" -> {
                mediaPlayer.play()
                result.success(null)
            }

            "pause" -> {
                mediaPlayer.pause()
                result.success(null)
            }

            "stop" -> {
                mediaPlayer.stop()
                result.success(null)
            }

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

            "setSurfaceType" -> {
                val useTex = call.argument<Boolean>("useTextureView") ?: true
                playerView.ensureSurfaceType(useTex)
                result.success(null)
            }

            "setTrack" -> {
                val typeStr = call.argument<String>("trackType") ?: "video"
                val groupIdx = (call.argument<Any>("groupIndex") as? Number)?.toInt() ?: -1
                val trackIdx = (call.argument<Any>("trackIndex") as? Number)?.toInt() ?: -1
                val trackType = when (typeStr.lowercase()) {
                    "audio" -> C.TRACK_TYPE_AUDIO
                    "text" -> C.TRACK_TYPE_TEXT
                    else -> C.TRACK_TYPE_VIDEO
                }
                mediaPlayer.setTrack(trackType, groupIdx, trackIdx)
                result.success(null)
            }

            "setPreferredVideoQuality" -> {
                val maxH = (call.argument<Any>("maxHeight") as? Number)?.toInt() ?: -1
                val maxB = (call.argument<Any>("maxBitrate") as? Number)?.toInt() ?: -1
                mediaPlayer.setPreferredVideoQuality(maxH, maxB)
                result.success(null)
            }

            "enterPip" -> {
                val entered = pipController?.invoke() ?: false
                result.success(entered)
            }

            "release" -> {
                pendingEvents.clear()
                playerView.detachFromEngine()
                if (activeOwnerViewId == viewId) {
                    mediaPlayer.stop()
                }
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
            } else if (pendingEvents.size < 30) {
                pendingEvents.add(data)
            }
        }
    }
}
