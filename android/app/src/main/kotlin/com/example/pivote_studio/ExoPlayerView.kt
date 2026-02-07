package com.example.pivote_studio

import android.content.Context
import android.net.Uri
import android.view.View
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

@UnstableApi
class ExoPlayerView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel = MethodChannel(messenger, "exoplayer_$id")

    init {
        methodChannel.setMethodCallHandler(this)
        playerView.useController = false
        playerView.controllerShowTimeoutMs = 0
        playerView.controllerHideOnTouch = false
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val url = call.argument<String>("url")
                val k1 = call.argument<String>("k1")
                val k2 = call.argument<String>("k2")

                if (url.isNullOrEmpty()) {
                    result.error("INVALID_URL", "URL requerida", null)
                    return
                }

                initializePlayer(url, k1, k2)
                result.success(true)
            }

            "play" -> {
                exoPlayer?.play()
                result.success(true)
            }

            "pause" -> {
                exoPlayer?.pause()
                result.success(true)
            }

            "stop" -> {
                exoPlayer?.stop()
                result.success(true)
            }

            "dispose" -> {
                disposePlayer()
                result.success(true)
            }

            "setVolume" -> {
                val volume = call.argument<Double>("volume") ?: 1.0
                exoPlayer?.volume = volume.toFloat()
                result.success(true)
            }

            "getPosition" -> {
                result.success(exoPlayer?.currentPosition ?: 0L)
            }

            "getDuration" -> {
                result.success(exoPlayer?.duration ?: 0L)
            }

            "isPlaying" -> {
                result.success(exoPlayer?.isPlaying ?: false)
            }

            else -> result.notImplemented()
        }
    }

    private fun initializePlayer(url: String, k1: String?, k2: String?) {
        disposePlayer()

        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("Mozilla/5.0 (Android)")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10000)
            .setReadTimeoutMs(10000)

        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                2_000,
                10_000,
                1_500,
                2_000
            )
            .build()

        val trackSelector = DefaultTrackSelector(playerView.context).apply {
            parameters = buildUponParameters()
                .setPreferredAudioLanguage("es")
                .setPreferredTextLanguage("es")
                .build()
        }

        exoPlayer = ExoPlayer.Builder(playerView.context)
            .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
            .setLoadControl(loadControl)
            .setTrackSelector(trackSelector)
            .build()

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(Uri.parse(url))

        // === DRM ClearKey ===
        if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
            println("🔐 DRM ClearKey activo")

            val clearKeyLicense = buildClearKeyLicense(k1, k2)

            val drmConfig = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
                .setLicenseUri(Uri.parse(clearKeyLicense))
                .build()

            mediaItemBuilder.setDrmConfiguration(drmConfig)
        }

        val mediaItem = mediaItemBuilder.build()

        exoPlayer?.apply {
            setMediaItem(mediaItem)
            playerView.player = this
            prepare()
            playWhenReady = true

            addListener(object : androidx.media3.common.Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    val mapped = when (state) {
                        androidx.media3.common.Player.STATE_IDLE -> "idle"
                        androidx.media3.common.Player.STATE_BUFFERING -> "buffering"
                        androidx.media3.common.Player.STATE_READY -> "ready"
                        androidx.media3.common.Player.STATE_ENDED -> "ended"
                        else -> "unknown"
                    }
                    methodChannel.invokeMethod("onStateChange", mapped)
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    methodChannel.invokeMethod("onPlayingChange", isPlaying)
                }

                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    methodChannel.invokeMethod(
                        "onError",
                        mapOf(
                            "message" to error.message,
                            "code" to error.errorCode
                        )
                    )
                }
            })
        }
    }

    /**
     * Construye la licencia ClearKey como data URI
     */
    private fun buildClearKeyLicense(kidHex: String, keyHex: String): String {
        val kidBase64 = hexToBase64(kidHex)
        val keyBase64 = hexToBase64(keyHex)

        val json = """
        {
          "keys": [
            {
              "kty": "oct",
              "kid": "$kidBase64",
              "k": "$keyBase64"
            }
          ],
          "type": "temporary"
        }
        """.trimIndent()

        val base64Json = android.util.Base64.encodeToString(
            json.toByteArray(),
            android.util.Base64.NO_WRAP or android.util.Base64.URL_SAFE
        )

        return "data:application/json;base64,$base64Json"
    }

    private fun hexToBase64(hex: String): String {
        val bytes = hexStringToByteArray(hex)
        return android.util.Base64.encodeToString(
            bytes,
            android.util.Base64.NO_WRAP or
                android.util.Base64.URL_SAFE or
                android.util.Base64.NO_PADDING
        )
    }

    private fun hexStringToByteArray(hex: String): ByteArray {
        val clean = hex.replace("-", "").replace(" ", "")
        val data = ByteArray(clean.length / 2)
        for (i in clean.indices step 2) {
            data[i / 2] =
                ((Character.digit(clean[i], 16) shl 4) +
                        Character.digit(clean[i + 1], 16)).toByte()
        }
        return data
    }

    private fun disposePlayer() {
        exoPlayer?.run {
            stop()
            release()
        }
        exoPlayer = null
        playerView.player = null
    }

    override fun dispose() {
        disposePlayer()
        methodChannel.setMethodCallHandler(null)
    }
}

@UnstableApi
class ExoPlayerViewFactory(
    private val messenger: BinaryMessenger
) : io.flutter.plugin.platform.PlatformViewFactory(
    io.flutter.plugin.common.StandardMessageCodec.INSTANCE
) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return ExoPlayerView(context, messenger, id, args as? Map<String?, Any?>)
    }
}
