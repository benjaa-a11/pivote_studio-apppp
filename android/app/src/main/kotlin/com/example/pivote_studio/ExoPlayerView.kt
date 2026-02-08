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
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
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
        
        playerView.apply {
            useController = false
            controllerShowTimeoutMs = 0
            controllerHideOnTouch = false
        }
        
        Log.d(TAG, "✅ PlayerView configurado")
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "📞 MethodCall: ${call.method}")
        
        when (call.method) {
            "initialize" -> {
                val url = call.argument<String>("url")
                val k1 = call.argument<String>("k1")
                val k2 = call.argument<String>("k2")
                
                Log.d(TAG, "🔧 URL: $url")
                if (k1 != null && k2 != null) {
                    Log.d(TAG, "🔐 K1: ${k1.take(16)}...")
                    Log.d(TAG, "🔐 K2: ${k2.take(16)}...")
                }
                
                if (url != null) {
                    try {
                        initializePlayer(url, k1, k2)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error: ${e.message}", e)
                        result.error("INIT_ERROR", e.message, null)
                    }
                } else {
                    result.error("INVALID_URL", "URL required", null)
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
                exoPlayer?.volume = volume?.toFloat() ?: 1.0f
                result.success(true)
            }
            
            "getPosition" -> {
                result.success(exoPlayer?.currentPosition ?: 0)
            }
            
            "getDuration" -> {
                result.success(exoPlayer?.duration ?: 0)
            }
            
            "isPlaying" -> {
                result.success(exoPlayer?.isPlaying ?: false)
            }
            
            else -> result.notImplemented()
        }
    }

    private fun initializePlayer(url: String, k1: String?, k2: String?) {
        Log.d(TAG, "🎬 initializePlayer START")
        
        disposePlayer()

        try {
            // DataSource optimizado (IGUAL QUE SHAKA)
            val dataSourceFactory = DefaultHttpDataSource.Factory().apply {
                setUserAgent("Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36")
                setAllowCrossProtocolRedirects(true)
                setConnectTimeoutMs(10000)  // Reducido de 15s a 10s
                setReadTimeoutMs(10000)
                setDefaultRequestProperties(hashMapOf(
                    "Accept" to "*/*",
                    "Accept-Encoding" to "gzip, deflate",
                    "Connection" to "keep-alive"
                ))
            }

            // LoadControl agresivo (IGUAL QUE SHAKA)
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    2000,   // minBufferMs (Shaka: rebufferingGoal: 2)
                    10000,  // maxBufferMs (Shaka: bufferingGoal: 10)
                    1500,   // bufferForPlaybackMs
                    2500    // bufferForPlaybackAfterRebufferMs
                )
                .setBackBuffer(
                    30000,  // Shaka: bufferBehind: 30
                    false
                )
                .build()

            // TrackSelector
            val trackSelector = DefaultTrackSelector(context).apply {
                parameters = buildUponParameters()
                    .setPreferredAudioLanguage("es")
                    .setForceHighestSupportedBitrate(false)
                    .build()
            }

            // ========================================
            // CONFIGURACIÓN DRM CLEARKEY (CORRECTO)
            // ========================================
            val mediaSourceFactory = if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
                Log.d(TAG, "🔐 Configurando DRM ClearKey")
                
                // Convertir claves hex a bytes
                val kidBytes = hexStringToByteArray(k1.replace("-", "").lowercase())
                val keyBytes = hexStringToByteArray(k2.replace("-", "").lowercase())
                
                Log.d(TAG, "🔑 KID bytes: ${kidBytes.size} bytes")
                Log.d(TAG, "🔑 KEY bytes: ${keyBytes.size} bytes")
                
                // Crear el mapa de claves (IGUAL QUE clearKeys de Shaka)
                val clearKeyMap = hashMapOf(
                    UUID.nameUUIDFromBytes(kidBytes) to keyBytes
                )
                
                // Crear DRM Session Manager con LocalMediaDrmCallback
                val drmCallback = LocalMediaDrmCallback(clearKeyMap)
                val drmSessionManager = DefaultDrmSessionManager.Builder()
                    .setUuidAndExoMediaDrmProvider(C.CLEARKEY_UUID) { uuid ->
                        androidx.media3.exoplayer.drm.FrameworkMediaDrm.newInstance(uuid)
                    }
                    .build(drmCallback)
                
                Log.d(TAG, "✅ DRM Session Manager creado")
                
                // MediaSourceFactory con DRM
                DefaultMediaSourceFactory(dataSourceFactory)
                    .setDrmSessionManagerProvider { drmSessionManager }
            } else {
                Log.d(TAG, "ℹ️ Sin DRM")
                DefaultMediaSourceFactory(dataSourceFactory)
            }

            // Crear ExoPlayer
            exoPlayer = ExoPlayer.Builder(context)
                .setMediaSourceFactory(mediaSourceFactory)
                .setLoadControl(loadControl)
                .setTrackSelector(trackSelector)
                .build()

            Log.d(TAG, "✅ ExoPlayer creado")

            // MediaItem simple
            val mediaItem = MediaItem.Builder()
                .setUri(Uri.parse(url))
                .build()

            // Listeners
            exoPlayer?.apply {
                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        val state = when (playbackState) {
                            Player.STATE_IDLE -> "IDLE"
                            Player.STATE_BUFFERING -> "BUFFERING"
                            Player.STATE_READY -> "READY"
                            Player.STATE_ENDED -> "ENDED"
                            else -> "UNKNOWN"
                        }
                        Log.d(TAG, "📺 State: $state")
                        methodChannel.invokeMethod("onStateChange", state.lowercase())
                        
                        if (playbackState == Player.STATE_READY) {
                            Log.d(TAG, "✅ READY - Reproduciendo")
                        }
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        Log.e(TAG, "❌ Player Error:")
                        Log.e(TAG, "  Type: ${error.errorCode}")
                        Log.e(TAG, "  Message: ${error.message}")
                        Log.e(TAG, "  Cause: ${error.cause?.message}")
                        
                        error.printStackTrace()
                        
                        methodChannel.invokeMethod("onError", mapOf(
                            "message" to (error.message ?: "Unknown"),
                            "code" to error.errorCode,
                            "cause" to (error.cause?.message ?: "")
                        ))
                    }

                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        Log.d(TAG, "▶️ Playing: $isPlaying")
                        methodChannel.invokeMethod("onPlayingChange", isPlaying)
                    }
                })

                setMediaItem(mediaItem)
                playerView.player = this
                
                Log.d(TAG, "🔄 Preparando...")
                prepare()
                
                Log.d(TAG, "▶️ Iniciando...")
                playWhenReady = true
                volume = 1.0f
            }

            Log.d(TAG, "✅ initializePlayer COMPLETE")

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error fatal: ${e.message}", e)
            throw e
        }
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
        
        Log.d(TAG, "✅ Disposed")
    }

    override fun dispose() {
        Log.d(TAG, "🗑️ Disposing ExoPlayerView")
        disposePlayer()
        methodChannel.setMethodCallHandler(null)
    }
}

@OptIn(UnstableApi::class)
class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    io.flutter.plugin.platform.PlatformViewFactory(
        io.flutter.plugin.common.StandardMessageCodec.INSTANCE
    ) {

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        Log.d("ExoPlayerViewFactory", "🏭 Creating ExoPlayerView ID: $id")
        val creationParams = args as? Map<String?, Any?>
        return ExoPlayerView(context, messenger, id, creationParams)
    }
}