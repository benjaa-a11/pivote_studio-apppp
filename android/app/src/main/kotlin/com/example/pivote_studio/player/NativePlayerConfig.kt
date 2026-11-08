package com.example.pivote_studio.player

import android.content.Context
import android.content.pm.ApplicationInfo
import android.net.Uri
import android.util.Log
import java.net.URLEncoder

/**
 * Configuración centralizada única del motor nativo Media3 ExoPlayer.
 *
 * Agrupa en un solo lugar:
 *   • Buffers de DefaultLoadControl optimizados para TV en vivo (arranque < 500ms)
 *   • Parámetros de LiveConfiguration (latencia objetivo y ajuste suave de velocidad)
 *   • Selección ABR inicial conservadora y límites por tipo de red (Wi-Fi vs Datos móviles)
 *   • Timeouts de red, detección de "solo audio sin video" y stream congelado
 *   • Backoff exponencial y límites de reintentos
 *   • Presets de cabeceras HTTP por proveedor y soporte de Proxy Cloudflare Worker
 *   • Logger de diagnóstico activo únicamente en modo DEBUG
 */
object NativePlayerConfig {

    const val TAG = "PivoteExoEngine"

    @Volatile
    var isDebugBuild: Boolean = false
        private set

    fun initDebugFlag(context: Context) {
        isDebugBuild = (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    // ── 1. Buffers de DefaultLoadControl (Live Zapping Rápido) ──────────────
    /** Buffer mínimo para empezar a reproducir el primer frame al hacer zapping. */
    const val BUFFER_FOR_PLAYBACK_MS = 450

    /** Buffer mínimo tras un corte/rebuffering para evitar micro-cortes sucesivos. */
    const val BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS = 1_200

    /** Buffer mínimo sostenido en memoria (liviano para +100 canales). */
    const val MIN_BUFFER_MS = 3_000

    /** Buffer máximo en memoria (reduce huella de RAM y calentamiento). */
    const val MAX_BUFFER_MS = 15_000

    /** Back-buffer corto para retroceso rápido en canales con ventana DVR. */
    const val BACK_BUFFER_MS = 8_000

    // ── 2. Configuración de Borde en Vivo (LiveConfiguration) ───────────────
    /** Latencia objetivo respecto al borde en vivo. */
    const val LIVE_TARGET_OFFSET_MS = 3_500L

    /** Distancia mínima permitida al borde antes de desacelerar levemente. */
    const val LIVE_MIN_OFFSET_MS = 1_500L

    /** Distancia máxima antes de acelerar o saltar al borde en vivo. */
    const val LIVE_MAX_OFFSET_MS = 10_000L

    /** Velocidad mínima de ajuste proporcional sin alterar el tono ni dar tirones. */
    const val LIVE_MIN_SPEED = 0.97f

    /** Velocidad máxima de ajuste para alcanzar el borde en vivo suavemente. */
    const val LIVE_MAX_SPEED = 1.03f

    /** Si tras una pausa o corte estamos a más de este umbral del live edge, saltar al borde. */
    const val LIVE_EDGE_RESYNC_THRESHOLD_MS = 18_000L

    // ── 3. ABR Inicial Conservador y Límites por Red ────────────────────────
    /**
     * Bitrate máximo durante el arranque (primeros frames) para que ExoPlayer elija un
     * perfil liviano instantáneamente y luego suba a 720p/1080p por ABR.
     */
    const val INITIAL_STARTUP_MAX_BITRATE = 1_600_000

    /** Límite automático en datos móviles cuando el usuario está en calidad "Auto". */
    const val CELLULAR_AUTO_MAX_HEIGHT = 720
    const val CELLULAR_AUTO_MAX_BITRATE = 2_800_000

    // ── 4. Timeouts de Red, Watchdogs y Reintentos ──────────────────────────
    const val HTTP_CONNECT_TIMEOUT_MS = 8_000
    const val HTTP_READ_TIMEOUT_MS = 10_000
    const val PROBE_SNIFF_TIMEOUT_MS = 3_500
    const val LOAD_ERROR_MIN_RETRIES = 2

    /** Máximo de reintentos de red con backoff exponencial en la misma fuente. */
    const val MAX_NETWORK_RETRIES = 3

    /** Base para el backoff exponencial: 500ms -> 1000ms -> 2000ms. */
    const val BASE_RETRY_DELAY_MS = 500L
    const val MAX_RETRY_DELAY_MS = 4_000L

    /** Intervalo del ticker de posición y salud del reproductor. */
    const val HEALTH_TICK_MS = 500L

    /**
     * Tiempo máximo en STATE_READY con pista de video detectada pero SIN renderizar
     * el primer frame (diagnóstico y corrección de "solo audio sin video").
     */
    const val AUDIO_WITHOUT_VIDEO_TIMEOUT_MS = 4_200L

    /** Tiempo máximo en STATE_BUFFERING continuo antes de forzar reconexión. */
    const val STALL_BUFFERING_TIMEOUT_MS = 9_000L

    /**
     * Tiempo máximo en STATE_READY (isPlaying=true) sin que avance la posición o el buffer
     * (detección de stream congelado en el servidor).
     */
    const val FROZEN_STREAM_TIMEOUT_MS = 6_500L

    // ── 5. User-Agents y Presets de Cabeceras HTTP ──────────────────────────
    const val DEFAULT_USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/130.0.0.0 Mobile Safari/537.36"

    const val DESKTOP_CHROME_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/131.0.0.0 Safari/537.36"

    const val IPTV_PLAYER_USER_AGENT = "VLC/3.0.20 LibVLC/3.0.20"

    val NVIDEO_HEADERS = mapOf(
        "User-Agent" to "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
        "Referer" to "https://nvideo.net/",
        "Origin" to "https://nvideo.net"
    )

    val FLOW_AR_HEADERS = mapOf(
        "Origin" to "https://portal.app.flow.com.ar",
        "Referer" to "https://portal.app.flow.com.ar/",
        "User-Agent" to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
    )

    val FLOW_PY_HEADERS = mapOf(
        "User-Agent" to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36",
        "Origin" to "https://portal.app.flow.com.py",
        "Referer" to "https://portal.app.flow.com.py/"
    )

    val PRIME_VIDEO_HEADERS = mapOf(
        "Referer" to "https://www.primevideo.com/",
        "User-Agent" to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AivAndroidPlayer/1.0 (AndroidDevice) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"
    )

    val MPD_HEADER_PRESETS: List<Map<String, String>> = listOf(
        FLOW_AR_HEADERS,
        FLOW_PY_HEADERS,
        PRIME_VIDEO_HEADERS
    )

    fun buildHlsHeaderPresets(requestUrl: String): List<Map<String, String>> {
        val uri = runCatching { Uri.parse(requestUrl) }.getOrNull()
        val scheme = uri?.scheme?.takeIf { it.isNotBlank() } ?: "https"
        val host = uri?.host?.takeIf { it.isNotBlank() }
        val baseOrigin = if (host != null) "$scheme://$host" else null

        val list = mutableListOf<Map<String, String>>()
        if (baseOrigin != null) {
            list.add(
                mapOf(
                    "User-Agent" to DESKTOP_CHROME_USER_AGENT,
                    "Referer" to "$baseOrigin/",
                    "Origin" to baseOrigin,
                    "Accept" to "*/*"
                )
            )
        }
        list.add(
            mapOf(
                "User-Agent" to IPTV_PLAYER_USER_AGENT,
                "Accept" to "*/*",
                "__STRIP_ORIGIN_REFERER__" to "true"
            )
        )
        if (baseOrigin != null) {
            list.add(
                mapOf(
                    "User-Agent" to DEFAULT_USER_AGENT,
                    "Referer" to "$baseOrigin/",
                    "Accept" to "*/*",
                    "__STRIP_ORIGIN_ONLY__" to "true"
                )
            )
        }
        return list
    }

    // ── 6. Soporte de Proxy (Cloudflare Worker) ─────────────────────────────
    /**
     * Plantilla global opcional para tu Cloudflare Worker.
     * Si un canal trae `proxyUrl` propio o si configurás esta constante, el motor puede
     * enrutar peticiones bloqueadas por IP/CORS a través del Worker.
     *
     * Soporta placeholders `{url}`, `{encodedUrl}`, `{referer}`, `{encodedReferer}` o
     * bien una URL base de Worker a la cual se le anexa `?url=<encodedUrl>`.
     */
    var defaultCloudflareWorkerUrl: String? = null

    fun wrapWithProxy(rawUrl: String, proxyTemplateOrBase: String?, referer: String? = null): String {
        val proxy = proxyTemplateOrBase?.trim()?.takeIf { it.isNotEmpty() }
            ?: defaultCloudflareWorkerUrl?.trim()?.takeIf { it.isNotEmpty() }
            ?: return rawUrl

        if (rawUrl.startsWith(proxy, ignoreCase = true)) return rawUrl

        val encodedUrl = runCatching { URLEncoder.encode(rawUrl, "UTF-8") }.getOrDefault(rawUrl)
        val encodedRef = runCatching { URLEncoder.encode(referer ?: "", "UTF-8") }.getOrDefault("")

        return when {
            proxy.contains("{encodedUrl}") || proxy.contains("{url}") -> {
                proxy
                    .replace("{encodedUrl}", encodedUrl)
                    .replace("{url}", rawUrl)
                    .replace("{encodedReferer}", encodedRef)
                    .replace("{referer}", referer ?: "")
            }
            proxy.contains("?") -> "$proxy&url=$encodedUrl" + (if (encodedRef.isNotEmpty()) "&referer=$encodedRef" else "")
            else -> "$proxy?url=$encodedUrl" + (if (encodedRef.isNotEmpty()) "&referer=$encodedRef" else "")
        }
    }

    // ── 7. Logger de Diagnóstico (Solo en Debug) ────────────────────────────
    fun logD(subTag: String, message: String) {
        if (isDebugBuild) Log.d("$TAG:$subTag", message)
    }

    fun logI(subTag: String, message: String) {
        if (isDebugBuild) Log.i("$TAG:$subTag", message)
    }

    fun logW(subTag: String, message: String) {
        if (isDebugBuild) Log.w("$TAG:$subTag", message)
    }

    fun logE(subTag: String, message: String, throwable: Throwable? = null) {
        if (isDebugBuild) {
            if (throwable != null) Log.e("$TAG:$subTag", message, throwable)
            else Log.e("$TAG:$subTag", message)
        }
    }
}

