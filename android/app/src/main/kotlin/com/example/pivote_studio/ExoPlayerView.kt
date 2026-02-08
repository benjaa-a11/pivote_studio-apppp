package com.example.pivote_studio

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Base64
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
import org.json.JSONArray
import org.json.JSONObject
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * 🔥 EXOPLAYER V4.0 ULTRA - CON BYTE SWAPPING UUID
 * 
 * SOLUCIÓN DEFINITIVA PARA DRM CLEARKEY:
 * ✅ Método 1: Conversión directa hex → base64
 * ✅ Método 2: UUID RFC 4122 con byte swapping
 * ✅ Prueba automática de ambos métodos
 * ✅ Logging exhaustivo
 * ✅ Watchdog integrado
 * 
 * @author Senior Android Engineer  
 * @version 4.0 ULTRA DEFINITIVO
 */
@OptIn(UnstableApi::class)
class ExoPlayerView(
    private val context: Context,
    messenger: BinaryMessenger,
    id: Int,
    creationParams: Map<String?, Any?>?
) : PlatformView, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "ExoPlayerView"
        
        // ══════════════════════════════════════════════════════════
        // CONVERSIÓN HEX → BYTES
        // ══════════════════════════════════════════════════════════
        
        private fun hexToBytes(hex: String): ByteArray {
            val cleanHex = hex.replace(Regex("[^0-9A-Fa-f]"), "")
            require(cleanHex.length % 2 == 0) {
                "Hex string must have even length: $hex"
            }
            return ByteArray(cleanHex.length / 2) { i ->
                cleanHex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
            }
        }
        
        /**
         * MÉTODO 1: Conversión directa hex → base64 URL-safe
         */
        private fun hexToBase64Direct(hex: String): String {
            val bytes = hexToBytes(hex)
            return Base64.encodeToString(bytes, 
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)
        }
        
        /**
         * MÉTODO 2: UUID RFC 4122 con byte swapping
         * 
         * UUID Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
         * Grupos:      time_low-time_mid-time_high-clock_seq-node
         * 
         * Los primeros 3 grupos necesitan byte swapping (little-endian)
         * Los últimos 2 grupos quedan en big-endian
         */
        private fun uuidToBase64(hex: String): String {
            val cleanHex = hex.replace("-", "")
            require(cleanHex.length == 32) {
                "UUID must be 32 hex chars: $hex"
            }
            
            // Parsear UUID
            val timeLow = cleanHex.substring(0, 8)     // 8 chars
            val timeMid = cleanHex.substring(8, 12)    // 4 chars
            val timeHigh = cleanHex.substring(12, 16)  // 4 chars
            val clockSeq = cleanHex.substring(16, 20)  // 4 chars
            val node = cleanHex.substring(20, 32)      // 12 chars
            
            // Aplicar byte swapping a los primeros 3 grupos
            val timeLowSwapped = timeLow.chunked(2).reversed().joinToString("")
            val timeMidSwapped = timeMid.chunked(2).reversed().joinToString("")
            val timeHighSwapped = timeHigh.chunked(2).reversed().joinToString("")
            
            // Reconstruir UUID con byte swapping
            val uuidSwapped = timeLowSwapped + timeMidSwapped + timeHighSwapped + clockSeq + node
            
            // Convertir a bytes y luego a base64
            val bytes = hexToBytes(uuidSwapped)
            return Base64.encodeToString(bytes,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)
        }
        
        /**
         * Crea JSON de licencia ClearKey - MÉTODO 1 (directo)
         */
        private fun createClearKeyLicenseMethod1(kid: String, key: String): String {
            val kidBase64 = hexToBase64Direct(kid)
            val keyBase64 = hexToBase64Direct(key)
            
            return JSONObject().apply {
                put("keys", JSONArray().apply {
                    put(JSONObject().apply {
                        put("kty", "oct")
                        put("k", keyBase64)
                        put("kid", kidBase64)
                    })
                })
                put("type", "temporary")
            }.toString()
        }
        
        /**
         * Crea JSON de licencia ClearKey - MÉTODO 2 (UUID swapping)
         */
        private fun createClearKeyLicenseMethod2(kid: String, key: String): String {
            val kidBase64 = uuidToBase64(kid)
            val keyBase64 = hexToBase64Direct(key)
            
            return JSONObject().apply {
                put("keys", JSONArray().apply {
                    put(JSONObject().apply {
                        put("kty", "oct")
                        put("k", keyBase64)
                        put("kid", kidBase64)
                    })
                })
                put("type", "temporary")
            }.toString()
        }
    }

    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel: MethodChannel = MethodChannel(messenger, "exoplayer_$id")
    
    // Watchdog
    private val handler = Handler(Looper.getMainLooper())
    private var watchdogRunnable: Runnable? = null
    private var lastPosition: Long = 0
    private var stalledCount = 0
    private val WATCHDOG_INTERVAL_MS = 5000L
    private val MAX_STALLED_CHECKS = 6
    
    // DRM retry
    private var currentDrmMethod = 1
    private var lastUrl: String? = null
    private var lastK1: String? = null
    private var lastK2: String? = null

    init {
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        Log.d(TAG, "🔥 ExoPlayerView V4.0 ULTRA DEFINITIVO - ID: $id")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        
        methodChannel.setMethodCallHandler(this)
        
        playerView.apply {
            useController = true
            controllerShowTimeoutMs = 5000
            controllerHideOnTouch = true
        }
        
        startWatchdog()
        
        Log.d(TAG, "✅ PlayerView + Watchdog inicializados")
    }

    override fun getView(): View = playerView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "📞 MethodCall: ${call.method}")
        
        when (call.method) {
            "initialize" -> {
                val url = call.argument<String>("url")
                val k1 = call.argument<String>("k1")
                val k2 = call.argument<String>("k2")
                
                Log.d(TAG, "───────────────────────────────────────────────────────")
                Log.d(TAG, "🔧 INITIALIZE V4.0 ULTRA")
                Log.d(TAG, "📺 URL: ${url?.take(100)}...")
                
                if (k1 != null && k2 != null) {
                    Log.d(TAG, "🔐 DRM ClearKey detectado")
                    Log.d(TAG, "   K1: ${k1.take(16)}... (${k1.length} chars)")
                    Log.d(TAG, "   K2: ${k2.take(16)}... (${k2.length} chars)")
                } else {
                    Log.d(TAG, "ℹ️  Stream sin DRM")
                }
                Log.d(TAG, "───────────────────────────────────────────────────────")
                
                if (url != null) {
                    try {
                        // Guardar parámetros para retry
                        lastUrl = url
                        lastK1 = k1
                        lastK2 = k2
                        currentDrmMethod = 1
                        
                        initializePlayer(url, k1, k2, method = 1)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error en initialize", e)
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
                val volume = call.argument<Double>("volume")?.toFloat() ?: 1.0f
                exoPlayer?.volume = volume.coerceIn(0f, 1f)
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

    private fun initializePlayer(url: String, k1: String?, k2: String?, method: Int = 1) {
        Log.d(TAG, "🎬 initializePlayer V4.0 - MÉTODO DRM: $method")
        
        disposePlayer()
        resetWatchdog()

        try {
            // DataSource
            Log.d(TAG, "📡 Configurando DataSource...")
            
            val dataSourceFactory = DefaultHttpDataSource.Factory().apply {
                setUserAgent("ExoPlayer/Flutter (Linux; Android 11)")
                setAllowCrossProtocolRedirects(true)
                setConnectTimeoutMs(10000)
                setReadTimeoutMs(10000)
                setDefaultRequestProperties(mapOf(
                    "Accept" to "*/*",
                    "Accept-Encoding" to "gzip, deflate",
                    "Connection" to "keep-alive"
                ))
            }
            
            Log.d(TAG, "✅ DataSource configurado")

            // LoadControl
            Log.d(TAG, "⚙️  Configurando buffering...")
            
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    2000,
                    10000,
                    2000,
                    3000
                )
                .setBackBuffer(30000, false)
                .setPrioritizeTimeOverSizeThresholds(true)
                .build()
            
            Log.d(TAG, "✅ Buffering configurado")

            // TrackSelector
            Log.d(TAG, "🎵 Configurando selector de pistas...")
            
            val trackSelector = DefaultTrackSelector(context).apply {
                parameters = buildUponParameters()
                    .setPreferredAudioLanguage("es")
                    .setPreferredTextLanguage("es")
                    .setForceHighestSupportedBitrate(false)
                    .build()
            }
            
            Log.d(TAG, "✅ TrackSelector configurado")

            // ExoPlayer
            Log.d(TAG, "🎮 Creando ExoPlayer...")
            
            exoPlayer = ExoPlayer.Builder(context)
                .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
                .setLoadControl(loadControl)
                .setTrackSelector(trackSelector)
                .build()

            Log.d(TAG, "✅ ExoPlayer creado")

            // MediaItem con DRM
            Log.d(TAG, "📦 Construyendo MediaItem...")
            
            val mediaItemBuilder = MediaItem.Builder().setUri(Uri.parse(url))

            if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
                Log.d(TAG, "═══════════════════════════════════════════════════════")
                Log.d(TAG, "🔐 CONFIGURANDO DRM CLEARKEY - MÉTODO $method")
                Log.d(TAG, "═══════════════════════════════════════════════════════")
                
                try {
                    val cleanK1 = k1.replace(Regex("[^0-9A-Fa-f]"), "")
                    val cleanK2 = k2.replace(Regex("[^0-9A-Fa-f]"), "")
                    
                    Log.d(TAG, "📋 Claves limpias:")
                    Log.d(TAG, "   K1: $cleanK1 (${cleanK1.length} chars)")
                    Log.d(TAG, "   K2: $cleanK2 (${cleanK2.length} chars)")
                    
                    require(cleanK1.length == 32) {
                        "K1 debe ser 32 chars hex (16 bytes). Actual: ${cleanK1.length}"
                    }
                    require(cleanK2.length == 32) {
                        "K2 debe ser 32 chars hex (16 bytes). Actual: ${cleanK2.length}"
                    }
                    
                    // Seleccionar método de conversión
                    val licenseJson = when (method) {
                        1 -> {
                            Log.d(TAG, "🔄 Usando MÉTODO 1: Conversión directa hex → base64")
                            val kidBase64 = hexToBase64Direct(cleanK1)
                            val keyBase64 = hexToBase64Direct(cleanK2)
                            Log.d(TAG, "   KID (directo): $kidBase64")
                            Log.d(TAG, "   KEY (directo): $keyBase64")
                            createClearKeyLicenseMethod1(cleanK1, cleanK2)
                        }
                        2 -> {
                            Log.d(TAG, "🔄 Usando MÉTODO 2: UUID RFC 4122 con byte swapping")
                            val kidBase64 = uuidToBase64(cleanK1)
                            val keyBase64 = hexToBase64Direct(cleanK2)
                            Log.d(TAG, "   KID (swapped): $kidBase64")
                            Log.d(TAG, "   KEY (directo): $keyBase64")
                            createClearKeyLicenseMethod2(cleanK1, cleanK2)
                        }
                        else -> throw IllegalArgumentException("Invalid DRM method: $method")
                    }
                    
                    Log.d(TAG, "📄 License JSON:")
                    Log.d(TAG, licenseJson)
                    
                    val jsonBase64 = Base64.encodeToString(
                        licenseJson.toByteArray(Charsets.UTF_8),
                        Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
                    )
                    
                    val licenseUri = "data:application/json;base64,$jsonBase64"
                    
                    Log.d(TAG, "🔗 License Data URI: ${licenseUri.take(100)}...")
                    
                    val drmConfiguration = MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
                        .setLicenseUri(licenseUri)
                        .build()
                    
                    mediaItemBuilder.setDrmConfiguration(drmConfiguration)
                    
                    Log.d(TAG, "═══════════════════════════════════════════════════════")
                    Log.d(TAG, "✅ DRM CLEARKEY CONFIGURADO - MÉTODO $method")
                    Log.d(TAG, "═══════════════════════════════════════════════════════")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    Log.e(TAG, "❌ ERROR CONFIGURANDO DRM - MÉTODO $method", e)
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    throw e
                }
            } else {
                Log.d(TAG, "ℹ️  Stream sin cifrado DRM")
            }

            val mediaItem = mediaItemBuilder.build()
            Log.d(TAG, "✅ MediaItem construido")

            // Listeners
            Log.d(TAG, "🎧 Configurando listeners...")
            
            exoPlayer?.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(playbackState: Int) {
                    val stateName = when (playbackState) {
                        Player.STATE_IDLE -> "IDLE"
                        Player.STATE_BUFFERING -> "BUFFERING"
                        Player.STATE_READY -> "READY"
                        Player.STATE_ENDED -> "ENDED"
                        else -> "UNKNOWN"
                    }
                    
                    Log.d(TAG, "📺 Estado: $stateName (método DRM: $currentDrmMethod)")
                    methodChannel.invokeMethod("onStateChange", stateName.lowercase())
                    
                    when (playbackState) {
                        Player.STATE_READY -> {
                            Log.d(TAG, "═══════════════════════════════════════════════════════")
                            Log.d(TAG, "🎉 READY - STREAM FUNCIONAL CON MÉTODO $currentDrmMethod")
                            Log.d(TAG, "═══════════════════════════════════════════════════════")
                            resetWatchdog()
                        }
                        Player.STATE_BUFFERING -> {
                            Log.d(TAG, "⏳ Buffering...")
                        }
                        Player.STATE_IDLE -> {
                            Log.w(TAG, "⚠️  IDLE detectado")
                        }
                    }
                }

                override fun onPlayerError(error: PlaybackException) {
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    Log.e(TAG, "❌ PLAYER ERROR - MÉTODO DRM: $currentDrmMethod")
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    Log.e(TAG, "Code: ${error.errorCode}")
                    Log.e(TAG, "Type: ${error.javaClass.simpleName}")
                    Log.e(TAG, "Message: ${error.message}")
                    Log.e(TAG, "Cause: ${error.cause?.message}")
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    
                    error.printStackTrace()
                    
                    // Si es error DRM y estamos en método 1, probar método 2
                    if (error.errorCode in 6000..6999 && currentDrmMethod == 1) {
                        Log.w(TAG, "🔄 ERROR DRM CON MÉTODO 1 - Intentando MÉTODO 2...")
                        currentDrmMethod = 2
                        
                        handler.postDelayed({
                            try {
                                lastUrl?.let { url ->
                                    initializePlayer(url, lastK1, lastK2, method = 2)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "❌ Error al reintentar con método 2", e)
                            }
                        }, 1000)
                    } else {
                        methodChannel.invokeMethod("onError", mapOf(
                            "message" to (error.message ?: "Error desconocido"),
                            "code" to error.errorCode,
                            "type" to error.javaClass.simpleName,
                            "cause" to (error.cause?.message ?: "")
                        ))
                    }
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    Log.d(TAG, "▶️  Reproduciendo: $isPlaying (método: $currentDrmMethod)")
                    methodChannel.invokeMethod("onPlayingChange", isPlaying)
                    
                    if (isPlaying) {
                        resetWatchdog()
                    }
                }
            })
            
            Log.d(TAG, "✅ Listeners configurados")

            // Preparar y reproducir
            exoPlayer?.apply {
                setMediaItem(mediaItem)
                playerView.player = this
                
                Log.d(TAG, "🔄 Preparando...")
                prepare()
                
                Log.d(TAG, "▶️  Iniciando (playWhenReady = true)...")
                playWhenReady = true
                volume = 1.0f
            }

            Log.d(TAG, "═══════════════════════════════════════════════════════")
            Log.d(TAG, "✅ INICIALIZACIÓN COMPLETA - MÉTODO DRM: $currentDrmMethod")
            Log.d(TAG, "═══════════════════════════════════════════════════════")

        } catch (e: Exception) {
            Log.e(TAG, "═══════════════════════════════════════════════════════")
            Log.e(TAG, "❌ ERROR FATAL", e)
            Log.e(TAG, "═══════════════════════════════════════════════════════")
            throw e
        }
    }

    // Watchdog
    private fun startWatchdog() {
        watchdogRunnable = object : Runnable {
            override fun run() {
                exoPlayer?.let { player ->
                    val currentPosition = player.currentPosition
                    val isPlaying = player.isPlaying
                    val playbackState = player.playbackState
                    
                    if (playbackState == Player.STATE_BUFFERING || 
                        (playbackState == Player.STATE_READY && !isPlaying)) {
                        
                        if (currentPosition == lastPosition && currentPosition > 0) {
                            stalledCount++
                            Log.w(TAG, "⚠️  WATCHDOG: Stream trabado (${stalledCount}/${MAX_STALLED_CHECKS})")
                            
                            if (stalledCount >= MAX_STALLED_CHECKS) {
                                Log.e(TAG, "🚨 WATCHDOG: STREAM TRABADO > 30s")
                                methodChannel.invokeMethod("onStreamStalled", null)
                                stalledCount = 0
                            }
                        } else {
                            resetWatchdog()
                        }
                    } else {
                        resetWatchdog()
                    }
                    
                    lastPosition = currentPosition
                }
                
                handler.postDelayed(this, WATCHDOG_INTERVAL_MS)
            }
        }
        
        handler.postDelayed(watchdogRunnable!!, WATCHDOG_INTERVAL_MS)
        Log.d(TAG, "🐕 Watchdog iniciado")
    }
    
    private fun stopWatchdog() {
        watchdogRunnable?.let {
            handler.removeCallbacks(it)
            watchdogRunnable = null
        }
        Log.d(TAG, "🐕 Watchdog detenido")
    }
    
    private fun resetWatchdog() {
        stalledCount = 0
        lastPosition = 0
    }

    private fun disposePlayer() {
        if (exoPlayer != null) {
            Log.d(TAG, "🗑️  Disposing player...")
            
            stopWatchdog()
            
            exoPlayer?.apply {
                stop()
                release()
            }
            exoPlayer = null
            playerView.player = null
            
            resetWatchdog()
            
            Log.d(TAG, "✅ Player disposed")
        }
    }

    override fun dispose() {
        Log.d(TAG, "🗑️  Disposing ExoPlayerView")
        disposePlayer()
        methodChannel.setMethodCallHandler(null)
    }
}

@OptIn(UnstableApi::class)
class ExoPlayerViewFactory(private val messenger: BinaryMessenger) :
    io.flutter.plugin.platform.PlatformViewFactory(
        io.flutter.plugin.common.StandardMessageCodec.INSTANCE
    ) {

    companion object {
        private const val TAG = "ExoPlayerViewFactory"
    }

    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        Log.d(TAG, "🏭 Creating ExoPlayerView V4.0 ULTRA - ID: $id")
        val creationParams = args as? Map<String?, Any?>
        return ExoPlayerView(context, messenger, id, creationParams)
    }
}