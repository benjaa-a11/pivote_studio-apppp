package com.example.pivote_studio

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.annotation.OptIn
import androidx.media3.common.C
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
 * Channels (aislados por viewId):
 *   MethodChannel  pivote/player_methods_$viewId  → comandos Flutter → Android
 *   EventChannel   pivote/player_events_$viewId   → estado Android  → Flutter
 *
 * Métodos soportados:
 *   prepare, play, pause, seekTo, setVolume, setPlaybackSpeed,
 *   setTrack, setPreferredVideoQuality, release
 *
 * Eventos emitidos (map con clave "event"):
 *   ready, stateChanged, position, tracksChanged, error, ended
 */
@OptIn(UnstableApi::class)
class ExoPlayerPlatformView(
    private val context: Context,
    private val viewId: Int,
    messenger: BinaryMessenger,
    creationParams: Map<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler, NativePlayerListener {

    private val methodChannel = MethodChannel(messenger, "pivote/player_methods_$viewId")
    private val eventChannel  = EventChannel(messenger, "pivote/player_events_$viewId")

    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private val mediaPlayer = NativeMediaPlayer(context)
    private val playerView  = NativePlayerView(context)

    private var isDisposed = false

    // ── Init ──────────────────────────────────────────────────────────────────

    init {
        methodChannel.setMethodCallHandler(this)

        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { eventSink = events }
            override fun onCancel(arguments: Any?) { eventSink = null }
        })

        // NativePlayerView recibe primero los callbacks para su UI y los reenvía
        // al PlatformView, que los publica por EventChannel hacia Flutter.
        playerView.attachPlayer(mediaPlayer, this)

        // Preparar con parámetros de creación si los hay
        if (creationParams != null) {
            val ch = StreamChannel.fromMap(creationParams)
            if (ch.originalUrl.isNotBlank()) {
                mediaPlayer.prepare(ch)
                playerView.bindChannel(ch)
            }
        }
    }

    // ── PlatformView ──────────────────────────────────────────────────────────

    override fun getView(): View = playerView

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        playerView.detachPlayer()
        mediaPlayer.release()
        methodChannel.setMethodCallHandler(null)
        eventSink = null
    }

    // ── MethodCallHandler ─────────────────────────────────────────────────────

    @Suppress("UNCHECKED_CAST")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isDisposed) { result.error("DISPOSED", "El reproductor ya fue liberado", null); return }

        when (call.method) {

            "prepare" -> {
                val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                val ch   = StreamChannel.fromMap(args)
                mediaPlayer.prepare(ch)
                playerView.bindChannel(ch)
                result.success(null)
            }

            "play"  -> { mediaPlayer.play();  result.success(null) }
            "pause" -> { mediaPlayer.pause(); result.success(null) }

            "seekTo" -> {
                val ms = (call.argument<Any>("positionMs") as? Number)?.toLong() ?: 0L
                mediaPlayer.seekTo(ms)
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

            "setTrack" -> {
                val typeStr  = call.argument<String>("trackType") ?: "video"
                val groupIdx = (call.argument<Any>("groupIndex")  as? Number)?.toInt() ?: 0
                val trackIdx = (call.argument<Any>("trackIndex")  as? Number)?.toInt() ?: 0
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
                playerView.detachPlayer()
                mediaPlayer.release()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ── NativePlayerListener → EventSink ─────────────────────────────────────

    override fun onReady(durationMs: Long, isLive: Boolean, videoWidth: Int, videoHeight: Int) {
        emit(mapOf(
            "event"       to "ready",
            "durationMs"  to durationMs,
            "isLive"      to isLive,
            "videoWidth"  to videoWidth,
            "videoHeight" to videoHeight
        ))
    }

    override fun onStateChanged(playbackState: Int, isPlaying: Boolean) {
        val stateStr = when (playbackState) {
            1    -> "idle"
            2    -> "buffering"
            3    -> "ready"
            4    -> "ended"
            else -> "idle"
        }
        emit(mapOf(
            "event"         to "stateChanged",
            "playbackState" to stateStr,
            "isPlaying"     to isPlaying
        ))
    }

    override fun onPosition(positionMs: Long, bufferedMs: Long) {
        emit(mapOf(
            "event"       to "position",
            "positionMs"  to positionMs,
            "bufferedMs"  to bufferedMs
        ))
    }

    override fun onTracksChanged(tracks: Tracks) {
        val videoTracks = mutableListOf<Map<String, Any>>()
        val audioTracks = mutableListOf<Map<String, Any>>()
        val textTracks  = mutableListOf<Map<String, Any>>()

        tracks.groups.forEachIndexed { groupIdx, group ->
            for (trackIdx in 0 until group.length) {
                val fmt = group.getTrackFormat(trackIdx)
                val entry = mapOf(
                    "groupIndex"  to groupIdx,
                    "trackIndex"  to trackIdx,
                    "isSelected"  to group.isTrackSelected(trackIdx),
                    "bitrate"     to (fmt.bitrate.takeIf { it != -1 } ?: 0),
                    "width"       to (fmt.width.takeIf  { it != -1 } ?: 0),
                    "height"      to (fmt.height.takeIf { it != -1 } ?: 0),
                    "language"    to (fmt.language ?: ""),
                    "label"       to (fmt.label ?: ""),
                    "mimeType"    to (fmt.sampleMimeType ?: "")
                )
                when (group.type) {
                    C.TRACK_TYPE_VIDEO -> videoTracks.add(entry)
                    C.TRACK_TYPE_AUDIO -> audioTracks.add(entry)
                    C.TRACK_TYPE_TEXT  -> textTracks.add(entry)
                }
            }
        }

        emit(mapOf(
            "event"       to "tracksChanged",
            "videoTracks" to videoTracks,
            "audioTracks" to audioTracks,
            "textTracks"  to textTracks
        ))
    }

    override fun onError(errorInfo: PlayerErrorInfo) {
        emit(mapOf(
            "event"     to "error",
            "errorCode" to errorInfo.errorCode,
            "message"   to errorInfo.technicalMessage,
            "isFatal"   to true
        ))
    }

    override fun onEnded() {
        emit(mapOf("event" to "ended"))
    }

    // ── Helper ────────────────────────────────────────────────────────────────

    private fun emit(data: Map<String, Any?>) {
        mainHandler.post {
            if (!isDisposed) eventSink?.success(data)
        }
    }
}
