package com.example.pivote_studio

import android.content.Context
import android.net.Uri
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
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.*

@OptIn(UnstableApi::class)
class ExoPlayerView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "ExoPlayerView"
    }

    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel: MethodChannel = MethodChannel(messenger, "exoplayer_$id")

    init {
        Log.d(TAG, "🎬 Inicializando ExoPlayerView con ID: $id")
        methodChannel.setMethodCallHandler(this)
        
        // Configurar PlayerView
        playerView.apply {
            useController = false
            controllerShowTimeoutMs = 0
            controllerHideOnTouch = false
        }
        
        Log.d(TAG, "✅ PlayerView configurado")
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "📞 MethodCall recibido: ${call.method}")
        
        when (call.method) {
            "initialize" -> {
                val url = call.argument<String>("url")
                val k1 = call.argument<String>("k1")
                val k2 = call.argument<String>("k2")
                
                Log.d(TAG, "🔧 Inicializando con URL: $url")
                if (k1 != null && k2 != null) {
                    Log.d(TAG, "🔐 DRM Keys - K1: ${k1.take(16)}..., K2: ${k2.take(16)}...")
                }
                
                if (url != null) {
                    try {
                        initializePlayer(url, k1, k2)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error en initialize: ${e.message}", e)
                        result.error("INIT_ERROR", e.message, e.stackTraceToString())
                    }
                } else {
                    Log.e(TAG, "❌ URL es null")
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
                    result.error("INVALID_VOLUME", "Volume required", null)
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
        Log.d(TAG, "🎬 initializePlayer START")
        
        // Limpiar player anterior
        disposePlayer()

        try {
            // Configurar DataSource con headers optimizados
            val dataSourceFactory = DefaultHttpDataSource.Factory().apply {
                setUserAgent("Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36")
                setAllowCrossProtocolRedirects(true)
                setConnectTimeoutMs(15000)
                setReadTimeoutMs(15000)
                setDefaultRequestProperties(hashMapOf(
                    "Accept" to "*/*",
                    "Accept-Encoding" to "gzip, deflate",
                    "Connection" to "keep-alive"
                ))
            }

            // Configurar LoadControl para buffering agresivo
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    3000,   // minBufferMs - buffer mínimo antes de empezar
                    15000,  // maxBufferMs - buffer máximo
                    1500,   // bufferForPlaybackMs - buffer para iniciar playback
                    2500    // bufferForPlaybackAfterRebufferMs - buffer después de rebuffer
                )
                .setBackBuffer(
                    20000,  // backBufferDurationMs - mantener 20s atrás
                    false   // retainBackBufferFromKeyframe
                )
                .build()

            // Configurar TrackSelector
            val trackSelector = DefaultTrackSelector(context).apply {
                parameters = buildUponParameters()
                    .setPreferredAudioLanguage("es")
                    .setPreferredTextLanguage("es")
                    .setForceHighestSupportedBitrate(false) // Permitir ABR
                    .build()
            }

            // Crear ExoPlayer
            exoPlayer = ExoPlayer.Builder(context)
                .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
                .setLoadControl(loadControl)
                .setTrackSelector(trackSelector)
                .build()

            Log.d(TAG, "✅ ExoPlayer creado")

            // Construir MediaItem
            val mediaItemBuilder = MediaItem.Builder()
                .setUri(Uri.parse(url))

            // Configurar DRM si hay claves
            if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
                Log.d(TAG, "🔐 Configurando DRM ClearKey")
                
                try {
                    // Convertir hex a base64 URL-safe
                    val kidBase64 = hexToBase64UrlSafe(k1)
                    val keyBase64 = hexToBase64UrlSafe(k2)
                    
                    Log.d(TAG, "🔑 KID (hex): $k1")
                    Log.d(TAG, "🔑 KID (b64): $kidBase64")
                    Log.d(TAG, "🔑 KEY (hex): $k2")
                    Log.d(TAG, "🔑 KEY (b64): $keyBase64")
                    
                    // Crear JSON de licencia ClearKey
                    val clearKeyJson = """
                        {
                            "keys": [{
                                "kty": "oct",
                                "k": "$keyBase64",
                                "kid": "$kidBase64"
                            }],
                            "type": "temporary"
                        }
                    """.trimIndent()
                    
                    Log.d(TAG, "📄 ClearKey JSON: $clearKeyJson")
                    
                    // Convertir JSON a Base64
                    val jsonBase64 = Base64.getEncoder()
                        .encodeToString(clearKeyJson.toByteArray(Charsets.UTF_8))
                        .replace("+", "-")
                        .replace("/", "_")
                        .replace("=", "")
                    
                    val licenseUri = "data:application/json;base64,$jsonBase64"
                    
                    Log.d(TAG, "🔗 License URI: ${licenseUri.take(100)}...")
                    
                    // Configurar DRM
                    val drmConfiguration = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
                        .setLicenseUri(licenseUri)
                        .build()
                    
                    mediaItemBuilder.setDrmConfiguration(drmConfiguration)
                    Log.d(TAG, "✅ DRM configurado correctamente")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error configurando DRM: ${e.message}", e)
                    throw e
                }
            } else {
                Log.d(TAG, "ℹ️ Sin DRM (stream sin cifrar)")
            }

            val mediaItem = mediaItemBuilder.build()

            // Configurar listeners
            exoPlayer?.apply {
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        val stateName = when (playbackState) {
                            Player.STATE_IDLE -> "IDLE"
                            Player.STATE_BUFFERING -> "BUFFERING"
                            Player.STATE_READY -> "READY"
                            Player.STATE_ENDED -> "ENDED"
                            else -> "UNKNOWN"
                        }
                        Log.d(TAG, "📺 State changed: $stateName")
                        
                        methodChannel.invokeMethod("onStateChange", stateName.lowercase())
                        
                        when (playbackState) {
                            Player.STATE_READY -> {
                                Log.d(TAG, "✅ Player READY - reproduciendo")
                            }
                            Player.STATE_BUFFERING -> {
                                Log.d(TAG, "⏳ Player BUFFERING...")
                            }
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        Log.e(TAG, "❌ Player Error:")
                        Log.e(TAG, "  - Type: ${error.errorCode}")
                        Log.e(TAG, "  - Message: ${error.message}")
                        Log.e(TAG, "  - Cause: ${error.cause?.message}")
                        
                        error.printStackTrace()
                        
                        methodChannel.invokeMethod("onError", mapOf(
                            "message" to (error.message ?: "Unknown error"),
                            "code" to error.errorCode,
                            "cause" to (error.cause?.message ?: "")
                        ))
                    }

                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        Log.d(TAG, "▶️ Is Playing: $isPlaying")
                        methodChannel.invokeMethod("onPlayingChange", isPlaying)
                    }
                })

                // Asignar media item y preparar
                setMediaItem(mediaItem)
                playerView.player = this
                
                Log.d(TAG, "🔄 Preparando player...")
                prepare()
                
                Log.d(TAG, "▶️ Iniciando reproducción...")
                playWhenReady = true
                volume = 1.0f
            }

            Log.d(TAG, "✅ initializePlayer COMPLETE")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error fatal en initializePlayer: ${e.message}", e)
            throw e
        }
    }

    /**
     * Convierte hex string a Base64 URL-safe sin padding
     */
    private fun hexToBase64UrlSafe(hex: String): String {
        val cleanHex = hex.replace("-", "").replace(" ", "").lowercase()
        val bytes = hexStringToByteArray(cleanHex)
        return Base64.getEncoder()
            .encodeToString(bytes)
            .replace("+", "-")
            .replace("/", "_")
            .replace("=", "")
    }

    /**
     * Convierte hex string a ByteArray
     */
    private fun hexStringToByteArray(hex: String): ByteArray {
        val len = hex.length
        val data = ByteArray(len / 2)
        
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(hex[i], 16) shl 4) +
                    Character.digit(hex[i + 1], 16)).toByte()
            i += 2
        }
        
        return data
    }

    private fun disposePlayer() {
        Log.d(TAG, "🗑️ Disposing player")
        
        exoPlayer?.apply {
            stop()
            release()
        }
        exoPlayer = null
        playerView.player = null
        
        Log.d(TAG, "✅ Player disposed")
    }

    override fun dispose() {
        Log.d(TAG, "🗑️ Disposing ExoPlayerView")
        disposePlayer()
        methodChannel.setMethodCallHandler(null)
    }
}

/**
 * Factory para crear instancias de ExoPlayerView
 */
@OptIn(UnstableApi::class)
class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    io.flutter.plugin.platform.PlatformViewFactory(
        io.flutter.plugin.common.StandardMessageCodec.INSTANCE
    ) {

    companion object {
        private const val TAG = "ExoPlayerViewFactory"
    }

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        Log.d(TAG, "🏭 Creating ExoPlayerView with ID: $id")
        val creationParams = args as? Map<String?, Any?>
        return ExoPlayerView(context, messenger, id, creationParams)
    }
}