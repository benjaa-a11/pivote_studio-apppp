package com.example.pivote_studio.network

import android.annotation.SuppressLint
import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import java.net.CookieHandler
import java.net.CookieManager
import java.net.CookiePolicy
import java.security.SecureRandom
import java.security.cert.X509Certificate
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager

/**
 * Fábrica de DataSources HTTP para Media3 ExoPlayer.
 *
 *   • Headers dinámicos por canal (User-Agent, Referer, Origin, Cookie, Authorization…)
 *   • Redirecciones cross-protocol (http ⇄ https), habituales en CDNs IPTV y enlaces M3U8 claros
 *   • Cookies persistentes en memoria (tokens de sesión devueltos por el servidor)
 *   • Tolerancia SSL/TLS para servidores M3U8 regionales con cadenas de certificados incompletas
 *   • Soporte de esquemas locales (file://, content://, asset://) vía [DefaultDataSource]
 */
@OptIn(UnstableApi::class)
object StreamHttpDataSourceFactory {

    const val DEFAULT_USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/130.0.0.0 Mobile Safari/537.36"

    const val DESKTOP_CHROME_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/131.0.0.0 Safari/537.36"

    const val IPTV_PLAYER_USER_AGENT =
        "VLC/3.0.20 LibVLC/3.0.20"

    private const val CONNECT_TIMEOUT_MS = 10_000
    private const val READ_TIMEOUT_MS    = 12_000

    // ── Presets de Headers para Streamings & MPD ────────────────────────────

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
        "Referer" to "https://portal.app.flow.py/"
    )

    val PRIME_VIDEO_HEADERS = mapOf(
        "Referer" to "https://www.primevideo.com/",
        "User-Agent" to "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AivAndroidPlayer/1.0 (AndroidDevice) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36"
    )

    /**
     * Lista ordenada de perfiles de headers para streams MPD/DASH que requieren
     * cabeceras específicas (Flow AR, Flow PY, PrimeVideo).
     */
    val MPD_HEADER_PRESETS: List<Map<String, String>> = listOf(
        FLOW_AR_HEADERS,
        FLOW_PY_HEADERS,
        PRIME_VIDEO_HEADERS
    )

    /**
     * Genera perfiles de respaldo para enlaces HLS / M3U8 claros cuando el primer intento
     * recibe 403/401/400 o bloqueo CORS del CDN:
     *   1. Same-Origin Referer + Origin + Chrome Desktop
     *   2. Sin Origin/Referer + User-Agent de reproductor nativo (evita bloqueos CORS en Wowza/Flussonic/Xtream)
     *   3. Same-Origin Referer (sin Origin) + Chrome Mobile
     */
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
        // Perfil limpio sin Origin ni Referer (indicado por "__STRIP_ORIGIN_REFERER__")
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

    init {
        // Muchos orígenes IPTV y HLS entregan cookies de sesión en el manifiesto que luego
        // exigen en los segmentos .ts / .m4s.
        if (CookieHandler.getDefault() == null) {
            CookieHandler.setDefault(CookieManager(null, CookiePolicy.ACCEPT_ALL))
        }
        installPermissiveSslIfNeeded()
    }

    @SuppressLint("CustomX509TrustManager", "TrustAllX509TrustManager")
    private fun installPermissiveSslIfNeeded() {
        runCatching {
            val trustAll = arrayOf<TrustManager>(
                object : X509TrustManager {
                    override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                    override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) = Unit
                    override fun getAcceptedIssuers(): Array<X509Certificate> = emptyArray()
                }
            )
            val sslContext = SSLContext.getInstance("TLS")
            sslContext.init(null, trustAll, SecureRandom())
            HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.socketFactory)
            HttpsURLConnection.setDefaultHostnameVerifier { _, _ -> true }
        }
    }

    private fun normalizeHeaderKey(key: String): String = when (key.trim().lowercase()) {
        "user-agent", "user_agent", "useragent" -> "User-Agent"
        "referer", "referrer"                   -> "Referer"
        "origin"                                -> "Origin"
        "cookie"                                -> "Cookie"
        "authorization"                         -> "Authorization"
        "accept"                                -> "Accept"
        else                                    -> key.trim()
    }

    /**
     * Crea un [DefaultHttpDataSource.Factory] configurado con los headers del canal
     * y detección inteligente por dominio/formato.
     */
    fun createHttp(headers: Map<String, String>, requestUrl: String = ""): DefaultHttpDataSource.Factory {
        val normalized = LinkedHashMap<String, String>()
        headers.forEach { (k, v) ->
            val trimmedVal = v.trim()
            if (trimmedVal.isNotEmpty() && !k.startsWith("__")) {
                normalized[normalizeHeaderKey(k)] = trimmedVal
            }
        }

        val stripOriginReferer = headers["__STRIP_ORIGIN_REFERER__"] == "true"
        val stripOriginOnly = headers["__STRIP_ORIGIN_ONLY__"] == "true"

        val lowerUrl = requestUrl.lowercase()

        fun injectPresetIfAbsent(preset: Map<String, String>) {
            preset.forEach { (k, v) ->
                if (!normalized.containsKey(k)) {
                    normalized[k] = v
                }
            }
        }

        // Auto-inyectar headers óptimos según el dominio o patrón de la URL
        if (!stripOriginReferer) {
            when {
                // 1. nvideo.net
                lowerUrl.contains("nvideo.net") || lowerUrl.contains("nvideo") -> {
                    injectPresetIfAbsent(NVIDEO_HEADERS)
                }
                // 2. Flow Paraguay (cvattv.com.ar edge links como edge-mix01-ros.cvattv.com.ar y .com.py)
                lowerUrl.contains("cvattv.com.ar") || lowerUrl.contains("flow.com.py") ||
                    lowerUrl.contains("cvattv.com.py") || lowerUrl.contains(".com.py") -> {
                    injectPresetIfAbsent(FLOW_PY_HEADERS)
                }
                // 3. Prime Video / AivAndroidPlayer MPD
                lowerUrl.contains("aiv-cdn.net") || lowerUrl.contains("iad-nitro") ||
                    lowerUrl.contains("cenc-sd.mpd") || lowerUrl.contains("primevideo.com") ||
                    lowerUrl.contains("aiv-delivery.net") || lowerUrl.contains("pv-cdn.net") ||
                    lowerUrl.contains("d25xi40x97liuc") || lowerUrl.contains("atv-ps") -> {
                    injectPresetIfAbsent(PRIME_VIDEO_HEADERS)
                }
                // 4. Flow Argentina
                lowerUrl.contains("cdn-token.app.flow.com.ar") ||
                    lowerUrl.contains("cdn-flow-balancer.app.flow.com.ar") ||
                    lowerUrl.contains("app.flow.com.ar") ||
                    lowerUrl.contains("flow.com.ar") ||
                    lowerUrl.contains("cablevisionflow") ||
                    lowerUrl.contains("telecom.com.ar") -> {
                    injectPresetIfAbsent(FLOW_AR_HEADERS)
                }
            }
        }

        if (stripOriginReferer) {
            normalized.remove("Origin")
            normalized.remove("Referer")
        } else if (stripOriginOnly) {
            normalized.remove("Origin")
        }

        if (!normalized.containsKey("Accept")) {
            normalized["Accept"] = "*/*"
        }

        val userAgent = normalized["User-Agent"]?.takeIf { it.isNotBlank() } ?: DEFAULT_USER_AGENT
        val merged = normalized.filterKeys { !it.equals("User-Agent", ignoreCase = true) }

        return DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(CONNECT_TIMEOUT_MS)
            .setReadTimeoutMs(READ_TIMEOUT_MS)
            .setAllowCrossProtocolRedirects(true)
            .setKeepPostFor302Redirects(true)
            .apply { if (merged.isNotEmpty()) setDefaultRequestProperties(merged) }
    }

    /**
     * DataSource completo: HTTP con headers + esquemas locales.
     */
    fun create(context: Context, headers: Map<String, String>, requestUrl: String = ""): DataSource.Factory =
        DefaultDataSource.Factory(context.applicationContext, createHttp(headers, requestUrl))

    /** Compatibilidad con llamadas previas sin Context (sólo HTTP). */
    fun create(headers: Map<String, String>, requestUrl: String = ""): DataSource.Factory =
        createHttp(headers, requestUrl)
}
