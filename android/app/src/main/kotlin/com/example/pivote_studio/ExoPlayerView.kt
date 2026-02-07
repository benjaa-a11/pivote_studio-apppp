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
import androidx.media3.exoplayer.trackselection.AdaptiveTrackSelection
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.UUID

@UnstableApi
class ExoPlayerView(
    context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel: MethodChannel = MethodChannel(messenger, "exoplayer_$id")

    init {
        methodChannel.setMethodCallHandler(this)
        playerView.useController = false // Flutter controlará la UI
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
                
                if (url != null) {
                    initializePlayer(url, k1, k2)
                    result.success(true)
                } else {
                    result.error("INVALID_URL", "URL is required", null)
                }
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
                val volume = call.argument<Double>("volume")
                if (volume != null) {
                    exoPlayer?.volume = volume.toFloat()
                    result.success(true)
                } else {
                    result.error("INVALID_VOLUME", "Volume must be between 0.0 and 1.0", null)
                }
            }
            "getPosition" -> {
                val position = exoPlayer?.currentPosition ?: 0
                result.success(position)
            }
            "getDuration" -> {
                val duration = exoPlayer?.duration ?: 0
                result.success(duration)
            }
            "isPlaying" -> {
                val playing = exoPlayer?.isPlaying ?: false
                result.success(playing)
            }
            else -> result.notImplemented()
        }
    }

    private fun initializePlayer(url: String, k1: String?, k2: String?) {
        // Liberar player anterior si existe
        disposePlayer()

        // Configurar DataSource Factory con headers
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36")
            .setAllowCrossProtocolRedirects(true)
            .setConnectTimeoutMs(10000)
            .setReadTimeoutMs(10000)

        // Configurar LoadControl para buffering optimizado
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                2000,   // minBufferMs
                10000,  // maxBufferMs
                1500,   // bufferForPlaybackMs
                2000    // bufferForPlaybackAfterRebufferMs
            )
            .build()

        // Configurar TrackSelector adaptativo
        val trackSelector = DefaultTrackSelector(playerView.context).apply {
            parameters = buildUponParameters()
                .setPreferredAudioLanguage("es")
                .setPreferredTextLanguage("es")
                .build()
        }

        // Crear ExoPlayer
        exoPlayer = ExoPlayer.Builder(playerView.context)
            .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
            .setLoadControl(loadControl)
            .setTrackSelector(trackSelector)
            .build()

        // Construir MediaItem
        val mediaItemBuilder = MediaItem.Builder().setUri(Uri.parse(url))

        // Configurar DRM si se proporcionan claves
        if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
            println("🔐 Configurando DRM ClearKey")
            println("🔑 K1 (KID): $k1")
            println("🔑 K2 (Key): $k2")

            // Convertir hex a bytes
            val kidBytes = hexStringToByteArray(k1)
            val keyBytes = hexStringToByteArray(k2)

            // Crear DRM Configuration para ClearKey
            val drmConfiguration = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
                .setLicenseUri(null) // ClearKey no necesita servidor de licencias
                .setKeySetId(kidBytes)
                .build()

            // CRÍTICO: Construir URL de licencia ClearKey en formato JSON
            val clearKeyLicense = buildClearKeyLicense(k1, k2)
            val drmConfig = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
                .setLicenseUri(clearKeyLicense)
                .build()

            mediaItemBuilder.setDrmConfiguration(drmConfig)
        }

        val mediaItem = mediaItemBuilder.build()

        // Configurar player
        exoPlayer?.apply {
            setMediaItem(mediaItem)
            playerView.player = this
            prepare()
            playWhenReady = true

            // Listeners para debugging
            addListener(object : androidx.media3.common.Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    when (playbackState) {
                        androidx.media3.common.Player.STATE_IDLE -> {
                            println("📺 Player: IDLE")
                            methodChannel.invokeMethod("onStateChange", "idle")
                        }
                        androidx.media3.common.Player.STATE_BUFFERING -> {
                            println("📺 Player: BUFFERING")
                            methodChannel.invokeMethod("onStateChange", "buffering")
                        }
                        androidx.media3.common.Player.STATE_READY -> {
                            println("✅ Player: READY")
                            methodChannel.invokeMethod("onStateChange", "ready")
                        }
                        androidx.media3.common.Player.STATE_ENDED -> {
                            println("📺 Player: ENDED")
                            methodChannel.invokeMethod("onStateChange", "ended")
                        }
                    }
                }

                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    println("❌ Player Error: ${error.message}")
                    println("❌ Error Code: ${error.errorCode}")
                    println("❌ Stack: ${error.stackTraceToString()}")
                    
                    methodChannel.invokeMethod("onError", mapOf(
                        "message" to error.message,
                        "code" to error.errorCode
                    ))
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    println("▶️ Is Playing: $isPlaying")
                    methodChannel.invokeMethod("onPlayingChange", isPlaying)
                }
            })
        }

        println("🎬 ExoPlayer inicializado para: $url")
    }

    /**
     * Construye la URI de licencia ClearKey en formato data URI
     * Formato: data:application/json;base64,[base64_encoded_json]
     */
    private fun buildClearKeyLicense(kid: String, key: String): String {
        // Formato JSON requerido por ClearKey:
        // {"keys":[{"kty":"oct","k":"[base64_key]","kid":"[base64_kid]"}],"type":"temporary"}
        
        val kidBase64 = hexToBase64(kid)
        val keyBase64 = hexToBase64(key)
        
        val json = """
        {
            "keys": [
                {
                    "kty": "oct",
                    "k": "$keyBase64",
                    "kid": "$kidBase64"
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

    /**
     * Convierte string hexadecimal a Base64 (formato requerido por ClearKey)
     */
    private fun hexToBase64(hex: String): String {
        val bytes = hexStringToByteArray(hex)
        return android.util.Base64.encodeToString(
            bytes,
            android.util.Base64.NO_WRAP or android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING
        )
    }

    /**
     * Convierte string hexadecimal a ByteArray
     */
    private fun hexStringToByteArray(hex: String): ByteArray {
        val cleanHex = hex.replace("-", "").replace(" ", "")
        val len = cleanHex.length
        val data = ByteArray(len / 2)
        
        for (i in 0 until len step 2) {
            data[i / 2] = ((Character.digit(cleanHex[i], 16) shl 4) +
                    Character.digit(cleanHex[i + 1], 16)).toByte()
        }
        
        return data
    }

    private fun disposePlayer() {
        exoPlayer?.apply {
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

/**
 * Factory para crear instancias de ExoPlayerView
 */
@UnstableApi
class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    io.flutter.plugin.platform.PlatformViewFactory(
        io.flutter.plugin.common.StandardMessageCodec.INSTANCE
    ) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>
        return ExoPlayerView(context, messenger, id, creationParams)
    }
}