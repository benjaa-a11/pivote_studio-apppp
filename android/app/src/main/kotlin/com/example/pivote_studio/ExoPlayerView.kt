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

/**
 * 🔥 EXOPLAYER PROFESIONAL CON DRM CLEARKEY
 * 
 * ARQUITECTURA BASADA EN SHAKA PLAYER (PRODUCCIÓN):
 * ✅ Conversión claves DRM hex → base64 URL-safe
 * ✅ Buffering agresivo (2s-10s) igual que Shaka
 * ✅ WATCHDOG para detectar streams trabados (30s)
 * ✅ Logging exhaustivo para debugging
 * ✅ Manejo robusto de errores
 * 
 * @author Senior Android Engineer
 * @version 3.0 DEFINITIVA
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
        // CONVERSIÓN HEX → BASE64 (EXACTO A SHAKA PLAYER)
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
         * Convierte hex a Base64 URL-safe SIN padding (formato ClearKey)
         * EXACTO al formato que usa Shaka Player
         */
        private fun hexToBase64UrlSafe(hex: String): String {
            val bytes = hexToBytes(hex)
            return Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)
        }
        
        /**
         * Crea JSON de licencia ClearKey según especificación W3C
         * https://www.w3.org/TR/encrypted-media/#clear-key-license-format
         */
        private fun createClearKeyLicense(kid: String, key: String): String {
            val kidBase64 = hexToBase64UrlSafe(kid)
            val keyBase64 = hexToBase64UrlSafe(key)
            
            val keyObject = JSONObject().apply {
                put("kty", "oct")
                put("k", keyBase64)
                put("kid", kidBase64)
            }
            
            val keysArray = JSONArray().apply {
                put(keyObject)
            }
            
            return JSONObject().apply {
                put("keys", keysArray)
                put("type", "temporary")
            }.toString()
        }
    }

    private val playerView: PlayerView = PlayerView(context)
    private var exoPlayer: ExoPlayer? = null
    private val methodChannel: MethodChannel = MethodChannel(messenger, "exoplayer_$id")
    
    // ══════════════════════════════════════════════════════════
    // 🔥 WATCHDOG PARA DETECTAR STREAMS TRABADOS
    // ══════════════════════════════════════════════════════════
    private val handler = Handler(Looper.getMainLooper())
    private var watchdogRunnable: Runnable? = null
    private var lastPosition: Long = 0
    private var stalledCount = 0
    private val WATCHDOG_INTERVAL_MS = 5000L  // Check every 5 seconds
    private val MAX_STALLED_CHECKS = 6        // 6 checks = 30 seconds

    init {
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        Log.d(TAG, "🎬 ExoPlayerView PROFESIONAL inicializando ID: $id")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        
        methodChannel.setMethodCallHandler(this)
        
        playerView.apply {
            useController = true
            controllerShowTimeoutMs = 5000
            controllerHideOnTouch = true
        }
        
        startWatchdog()
        
        Log.d(TAG, "✅ PlayerView + Watchdog configurados")
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
                Log.d(TAG, "🔧 INITIALIZE llamado")
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
                        initializePlayer(url, k1, k2)
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

    private fun initializePlayer(url: String, k1: String?, k2: String?) {
        Log.d(TAG, "🎬 initializePlayer START")
        
        disposePlayer()
        resetWatchdog()

        try {
            // ═══════════════════════════════════════════════════════
            // PASO 1: DataSource con timeouts agresivos
            // ═══════════════════════════════════════════════════════
            Log.d(TAG, "📡 Configurando DataSource...")
            
            val dataSourceFactory = DefaultHttpDataSource.Factory().apply {
                setUserAgent("ExoPlayer/Flutter (Linux; Android 11)")
                setAllowCrossProtocolRedirects(true)
                setConnectTimeoutMs(10000)  // 10s como Shaka
                setReadTimeoutMs(10000)
                setDefaultRequestProperties(mapOf(
                    "Accept" to "*/*",
                    "Accept-Encoding" to "gzip, deflate",
                    "Connection" to "keep-alive"
                ))
            }
            
            Log.d(TAG, "✅ DataSource configurado (timeout: 10s)")

            // ═══════════════════════════════════════════════════════
            // PASO 2: LoadControl EXACTO A SHAKA PLAYER
            // ═══════════════════════════════════════════════════════
            Log.d(TAG, "⚙️  Configurando buffering (igual a Shaka)...")
            
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    2000,   // minBufferMs - SHAKA: rebufferingGoal: 2
                    10000,  // maxBufferMs - SHAKA: bufferingGoal: 10
                    2000,   // bufferForPlaybackMs - aumentado para DRM
                    3000    // bufferForPlaybackAfterRebufferMs - aumentado
                )
                .setBackBuffer(
                    30000,  // SHAKA: bufferBehind: 30
                    false
                )
                .setPrioritizeTimeOverSizeThresholds(true)
                .build()
            
            Log.d(TAG, "✅ Buffering: 2s-10s, backbuffer: 30s (como Shaka)")

            // ═══════════════════════════════════════════════════════
            // PASO 3: TrackSelector
            // ═══════════════════════════════════════════════════════
            Log.d(TAG, "🎵 Configurando selector de pistas...")
            
            val trackSelector = DefaultTrackSelector(context).apply {
                parameters = buildUponParameters()
                    .setPreferredAudioLanguage("es")
                    .setPreferredTextLanguage("es")
                    .setForceHighestSupportedBitrate(false)
                    .build()
            }
            
            Log.d(TAG, "✅ TrackSelector configurado")

            // ═══════════════════════════════════════════════════════
            // PASO 4: Crear ExoPlayer
            // ═══════════════════════════════════════════════════════
            Log.d(TAG, "🎮 Creando ExoPlayer...")
            
            exoPlayer = ExoPlayer.Builder(context)
                .setMediaSourceFactory(DefaultMediaSourceFactory(dataSourceFactory))
                .setLoadControl(loadControl)
                .setTrackSelector(trackSelector)
                .build()

            Log.d(TAG, "✅ ExoPlayer creado")

            // ═══════════════════════════════════════════════════════
            // PASO 5: MediaItem con DRM (FORMATO EXACTO A SHAKA)
            // ═══════════════════════════════════════════════════════
            Log.d(TAG, "📦 Construyendo MediaItem...")
            
            val mediaItemBuilder = MediaItem.Builder().setUri(Uri.parse(url))

            if (!k1.isNullOrEmpty() && !k2.isNullOrEmpty()) {
                Log.d(TAG, "═══════════════════════════════════════════════════════")
                Log.d(TAG, "🔐 CONFIGURANDO DRM CLEARKEY (FORMATO SHAKA)")
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
                    
                    val kidBase64 = hexToBase64UrlSafe(cleanK1)
                    val keyBase64 = hexToBase64UrlSafe(cleanK2)
                    
                    Log.d(TAG, "🔄 Conversión a Base64 URL-safe:")
                    Log.d(TAG, "   KID: $kidBase64")
                    Log.d(TAG, "   KEY: $keyBase64")
                    
                    val licenseJson = createClearKeyLicense(cleanK1, cleanK2)
                    
                    Log.d(TAG, "📄 License JSON (formato W3C):")
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
                    Log.d(TAG, "✅ DRM CLEARKEY CONFIGURADO (SHAKA FORMAT)")
                    Log.d(TAG, "═══════════════════════════════════════════════════════")
                    
                } catch (e: Exception) {
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    Log.e(TAG, "❌ ERROR CONFIGURANDO DRM", e)
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    throw e
                }
            } else {
                Log.d(TAG, "ℹ️  Stream sin cifrado DRM")
            }

            val mediaItem = mediaItemBuilder.build()
            Log.d(TAG, "✅ MediaItem construido")

            // ═══════════════════════════════════════════════════════
            // PASO 6: Listeners con logging exhaustivo
            // ═══════════════════════════════════════════════════════
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
                    
                    Log.d(TAG, "📺 Estado: $stateName")
                    methodChannel.invokeMethod("onStateChange", stateName.lowercase())
                    
                    when (playbackState) {
                        Player.STATE_READY -> {
                            Log.d(TAG, "═══════════════════════════════════════════════════════")
                            Log.d(TAG, "🎉 READY - STREAM FUNCIONAL")
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
                    Log.e(TAG, "❌ PLAYER ERROR")
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    Log.e(TAG, "Code: ${error.errorCode}")
                    Log.e(TAG, "Type: ${error.javaClass.simpleName}")
                    Log.e(TAG, "Message: ${error.message}")
                    Log.e(TAG, "Cause: ${error.cause?.message}")
                    Log.e(TAG, "═══════════════════════════════════════════════════════")
                    
                    error.printStackTrace()
                    
                    methodChannel.invokeMethod("onError", mapOf(
                        "message" to (error.message ?: "Error desconocido"),
                        "code" to error.errorCode,
                        "type" to error.javaClass.simpleName,
                        "cause" to (error.cause?.message ?: "")
                    ))
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    Log.d(TAG, "▶️  Reproduciendo: $isPlaying")
                    methodChannel.invokeMethod("onPlayingChange", isPlaying)
                    
                    if (isPlaying) {
                        resetWatchdog()
                    }
                }
            })
            
            Log.d(TAG, "✅ Listeners configurados")

            // ═══════════════════════════════════════════════════════
            // PASO 7: Preparar y reproducir
            // ═══════════════════════════════════════════════════════
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
            Log.d(TAG, "✅ INICIALIZACIÓN COMPLETA")
            Log.d(TAG, "═══════════════════════════════════════════════════════")

        } catch (e: Exception) {
            Log.e(TAG, "═══════════════════════════════════════════════════════")
            Log.e(TAG, "❌ ERROR FATAL", e)
            Log.e(TAG, "═══════════════════════════════════════════════════════")
            throw e
        }
    }

    // ══════════════════════════════════════════════════════════
    // 🔥 WATCHDOG IMPLEMENTATION (EXACTO A SHAKA detectarStalling)
    // ══════════════════════════════════════════════════════════
    
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
                            Log.w(TAG, "   Posición: ${currentPosition}ms, IsPlaying: $isPlaying, State: $playbackState")
                            
                            if (stalledCount >= MAX_STALLED_CHECKS) {
                                Log.e(TAG, "🚨 WATCHDOG: STREAM TRABADO > 30s - Notificando Flutter")
                                methodChannel.invokeMethod("onStreamStalled", null)
                                stalledCount = 0  // Reset para no spam
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
        Log.d(TAG, "🐕 Watchdog iniciado (check cada ${WATCHDOG_INTERVAL_MS}ms)")
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
        Log.d(TAG, "🏭 Creating ExoPlayerView ID: $id")
        val creationParams = args as? Map<String?, Any?>
        return ExoPlayerView(context, messenger, id, creationParams)
    }
}