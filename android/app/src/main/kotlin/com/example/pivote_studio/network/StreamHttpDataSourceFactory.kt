package com.example.pivote_studio.network

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import com.example.pivote_studio.data.StreamFormat
import com.example.pivote_studio.player.NativePlayerConfig
import java.io.InputStream
import java.net.CookieHandler
import java.net.CookieManager
import java.net.CookiePolicy
import java.net.HttpURLConnection
import java.net.URL

/**
 * Fábrica centralizada de DataSources HTTP y detector de formato por contenido/MIME.
 *
 * Características:
 *   • Headers dinámicos por canal (User-Agent, Referer, Origin, Cookie, Authorization)
 *   • Redirecciones cross-protocol automáticas (HTTP ⇄ HTTPS, 301/302/307/308)
 *   • Cookies de sesión en memoria (para tokens de borde HLS/DASH que rotan por segmento)
 *   • Detección activa de formato (Content-Type + primeros bytes / Magic Bytes) para URLs
 *     sin extensión o con Content-Type erróneo (ej. MPEG-TS directo, manifiestos en puertos :8080)
 *   • Timeouts agresivos pensados para TV en vivo (configurados en [NativePlayerConfig])
 */
@OptIn(UnstableApi::class)
object StreamHttpDataSourceFactory {

    private const val SUBTAG = "HttpDataSource"

    val MPD_HEADER_PRESETS: List<Map<String, String>>
        get() = NativePlayerConfig.MPD_HEADER_PRESETS

    fun buildHlsHeaderPresets(requestUrl: String): List<Map<String, String>> =
        NativePlayerConfig.buildHlsHeaderPresets(requestUrl)

    init {
        // Mantener cookies de sesión en memoria (requerido por CDNs que entregan Set-Cookie en el .m3u8/.mpd)
        if (CookieHandler.getDefault() == null) {
            CookieHandler.setDefault(CookieManager(null, CookiePolicy.ACCEPT_ALL))
        }
        // Activar reutilización de conexiones HTTP keep-alive en el pool nativo
        System.setProperty("http.keepAlive", "true")
        System.setProperty("http.maxConnections", "12")
    }

    private fun normalizeHeaderKey(key: String): String = when (key.trim().lowercase()) {
        "user-agent", "user_agent", "useragent" -> "User-Agent"
        "referer", "referrer" -> "Referer"
        "origin" -> "Origin"
        "cookie", "cookies" -> "Cookie"
        "authorization" -> "Authorization"
        "accept" -> "Accept"
        else -> key.trim()
    }

    /**
     * Construye el mapa normalizado de cabeceras combinando las del canal con los presets por dominio.
     */
    fun resolveEffectiveHeaders(headers: Map<String, String>, requestUrl: String): Map<String, String> {
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

        if (!stripOriginReferer) {
            when {
                lowerUrl.contains("nvideo.net") || lowerUrl.contains("nvideo") ->
                    injectPresetIfAbsent(NativePlayerConfig.NVIDEO_HEADERS)

                lowerUrl.contains("cvattv.com.ar") || lowerUrl.contains("flow.com.py") ||
                    lowerUrl.contains("cvattv.com.py") || lowerUrl.contains(".com.py") ->
                    injectPresetIfAbsent(NativePlayerConfig.FLOW_PY_HEADERS)

                lowerUrl.contains("aiv-cdn.net") || lowerUrl.contains("iad-nitro") ||
                    lowerUrl.contains("cenc-sd.mpd") || lowerUrl.contains("primevideo.com") ||
                    lowerUrl.contains("aiv-delivery.net") || lowerUrl.contains("pv-cdn.net") ||
                    lowerUrl.contains("d25xi40x97liuc") || lowerUrl.contains("atv-ps") ->
                    injectPresetIfAbsent(NativePlayerConfig.PRIME_VIDEO_HEADERS)

                lowerUrl.contains("cdn-token.app.flow.com.ar") ||
                    lowerUrl.contains("cdn-flow-balancer.app.flow.com.ar") ||
                    lowerUrl.contains("app.flow.com.ar") ||
                    lowerUrl.contains("flow.com.ar") ||
                    lowerUrl.contains("cablevisionflow") ||
                    lowerUrl.contains("telecom.com.ar") ->
                    injectPresetIfAbsent(NativePlayerConfig.FLOW_AR_HEADERS)
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
        if (!normalized.containsKey("Connection")) {
            normalized["Connection"] = "keep-alive"
        }

        return normalized
    }

    /**
     * Crea un [DefaultHttpDataSource.Factory] con soporte de redirecciones HTTP↔HTTPS y headers por canal.
     */
    fun createHttp(headers: Map<String, String>, requestUrl: String = ""): DefaultHttpDataSource.Factory {
        val effective = resolveEffectiveHeaders(headers, requestUrl)
        val userAgent = effective["User-Agent"]?.takeIf { it.isNotBlank() }
            ?: NativePlayerConfig.DEFAULT_USER_AGENT
        val requestProps = effective.filterKeys { !it.equals("User-Agent", ignoreCase = true) }

        return DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(NativePlayerConfig.HTTP_CONNECT_TIMEOUT_MS)
            .setReadTimeoutMs(NativePlayerConfig.HTTP_READ_TIMEOUT_MS)
            .setAllowCrossProtocolRedirects(true)
            .setKeepPostFor302Redirects(true)
            .apply {
                if (requestProps.isNotEmpty()) {
                    setDefaultRequestProperties(requestProps)
                }
            }
    }

    fun create(context: Context, headers: Map<String, String>, requestUrl: String = ""): DataSource.Factory =
        DefaultDataSource.Factory(context.applicationContext, createHttp(headers, requestUrl))

    /**
     * Inspecciona rápidamente una URL sin extensión (o dudosa) leyendo el Content-Type, la URL final
     * tras redirecciones (incluyendo HTTP→HTTPS) y los primeros 512 bytes del cuerpo:
     *   • `<MPD` o `application/dash+xml` → [StreamFormat.DASH]
     *   • `#EXTM3U` o `mpegurl`           → [StreamFormat.HLS]
     *   • Sync byte `0x47` (MPEG-TS 188B) o `video/mp2t` → [StreamFormat.PROGRESSIVE]
     */
    fun sniffStreamFormat(url: String, headers: Map<String, String>): StreamFormat? {
        var conn: HttpURLConnection? = null
        return try {
            var currentUrl = url
            var redirects = 0
            val effectiveHeaders = resolveEffectiveHeaders(headers, url)

            while (redirects < 6) {
                conn = (URL(currentUrl).openConnection() as HttpURLConnection).apply {
                    instanceFollowRedirects = false
                    connectTimeout = NativePlayerConfig.PROBE_SNIFF_TIMEOUT_MS
                    readTimeout = NativePlayerConfig.PROBE_SNIFF_TIMEOUT_MS
                    requestMethod = "GET"
                    effectiveHeaders.forEach { (k, v) -> setRequestProperty(k, v) }
                }

                val code = conn.responseCode
                if (code in listOf(301, 302, 303, 307, 308)) {
                    val location = conn.getHeaderField("Location") ?: break
                    conn.disconnect()
                    currentUrl = URL(URL(currentUrl), location).toString()
                    val redirectedLower = currentUrl.lowercase()
                    if (redirectedLower.contains(".mpd")) return StreamFormat.DASH
                    if (redirectedLower.contains(".m3u8")) return StreamFormat.HLS
                    redirects++
                    continue
                }
                break
            }

            val finalConn = conn ?: return null
            val contentType = (finalConn.contentType ?: "").lowercase()
            when {
                contentType.contains("dash+xml") || contentType.contains("application/mpd") ->
                    return StreamFormat.DASH
                contentType.contains("mpegurl") || contentType.contains("x-mpegurl") ->
                    return StreamFormat.HLS
                contentType.contains("mp2t") || contentType.contains("video/mp4") ||
                    contentType.contains("video/x-matroska") ->
                    return StreamFormat.PROGRESSIVE
            }

            // Inspeccionar los primeros bytes reales (para servidores con Content-Type: application/octet-stream o text/plain)
            val stream: InputStream = finalConn.inputStream
            val buffer = ByteArray(512)
            var totalRead = 0
            while (totalRead < buffer.size) {
                val r = stream.read(buffer, totalRead, buffer.size - totalRead)
                if (r <= 0) break
                totalRead += r
            }
            runCatching { stream.close() }

            if (totalRead <= 0) return null

            // 1. Verificar MPEG-TS directo: byte de sincronismo 0x47 ('G') cada 188 bytes
            if (buffer[0] == 0x47.toByte() && (totalRead < 189 || buffer[188] == 0x47.toByte())) {
                NativePlayerConfig.logD(SUBTAG, "Sniff detectó MPEG-TS directo (0x47 sync byte)")
                return StreamFormat.PROGRESSIVE
            }

            val headText = String(buffer, 0, totalRead, Charsets.UTF_8).trimStart()
            when {
                headText.startsWith("#EXTM3U", ignoreCase = true) || headText.contains("#EXT-X-", ignoreCase = true) -> {
                    NativePlayerConfig.logD(SUBTAG, "Sniff detectó manifiesto HLS (#EXTM3U)")
                    StreamFormat.HLS
                }
                headText.contains("<MPD", ignoreCase = true) || headText.contains("urn:mpeg:dash:schema:mpd", ignoreCase = true) -> {
                    NativePlayerConfig.logD(SUBTAG, "Sniff detectó manifiesto DASH (<MPD)")
                    StreamFormat.DASH
                }
                else -> null
            }
        } catch (e: Exception) {
            NativePlayerConfig.logD(SUBTAG, "Sniff omitido (${e.javaClass.simpleName}): ${e.message}")
            null
        } finally {
            runCatching { conn?.disconnect() }
        }
    }
}
