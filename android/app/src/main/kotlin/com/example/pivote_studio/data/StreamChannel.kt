package com.example.pivote_studio.data

import android.net.Uri
import java.net.URLDecoder

/**
 * Tipo de DRM que se va a usar para descifrar el stream.
 */
enum class DrmScheme { NONE, CLEARKEY, WIDEVINE, PLAYREADY }

/**
 * Formato de contenedor/manifiesto detectado o forzado.
 * [UNKNOWN] activa la detección por prueba (HLS → DASH → progresivo).
 */
enum class StreamFormat { HLS, DASH, SMOOTH, RTSP, PROGRESSIVE, UNKNOWN }

/**
 * Modelo de datos inmutable para canales de streaming de TV, radio y VOD.
 *
 * Compatible con:
 *   • HLS (m3u8) — TS / fMP4 / AES-128 / SAMPLE-AES / Widevine
 *   • MPEG-DASH (mpd) — CENC (cenc) y CBCS
 *   • Smooth Streaming (ism/manifest), RTSP, HTTP progresivo (mp4, ts, mkv, mp3, aac…)
 *   • ClearKey local (kid:k / JSON W3C) o servidor ClearKey remoto
 *   • Widevine / PlayReady con servidor de licencias y headers propios
 *   • Headers HTTP personalizados por canal (User-Agent, Referer, Origin, Cookie…)
 *   • Sintaxis pipe de listas M3U (`https://.../live.m3u8|Referer=...&User-Agent=...`)
 */
data class StreamChannel(
    val name: String,
    val type: String? = null,
    val icono: String? = null,
    val originalUrl: String,

    // ── DRM ─────────────────────────────────────────────────────────────────
    val drmScheme: DrmScheme = DrmScheme.NONE,

    /** ClearKey local: cadena "kid:XXX,k:YYY" o JSON W3C. */
    val clearKeyLicenseData: String? = null,

    /** URL del servidor de licencias (Widevine, PlayReady o ClearKey remoto). */
    val licenseUrl: String? = null,

    /** Headers adicionales para la solicitud de licencia. */
    val licenseHeaders: Map<String, String> = emptyMap(),

    /** Fuerza Widevine L3 (decodificación no segura). */
    val forceWidevineL3: Boolean = false,

    // ── HTTP ─────────────────────────────────────────────────────────────────
    val headers: Map<String, String> = emptyMap(),

    // ── Metadatos ────────────────────────────────────────────────────────────
    val globalIndex: Int? = null,
    val category: String? = null,
    val sourceGroup: String? = null,

    /** Identificador de sesión enviado por Flutter para descartar eventos obsoletos. */
    val sessionId: Int = 0
) {

    /** Compatibilidad con código previo. */
    val widevineLicenseUrl: String? get() = if (drmScheme == DrmScheme.WIDEVINE) licenseUrl else null
    val widevineLicenseHeaders: Map<String, String> get() = licenseHeaders

    val hasDrm: Boolean get() = drmScheme != DrmScheme.NONE

    /**
     * Formato declarado explícitamente (campo `type`) o inferido de la URL / DRM.
     */
    fun detectFormat(): StreamFormat {
        val uri = runCatching { Uri.parse(originalUrl) }.getOrNull()
        val scheme = uri?.scheme?.lowercase()
        if (scheme == "rtsp" || scheme == "rtsps") return StreamFormat.RTSP

        val path = (uri?.path ?: originalUrl).lowercase()
        val full = originalUrl.lowercase()

        // 1. Prioridad máxima: extensión o patrón claro en la URL
        if (path.endsWith(".m3u8") || path.endsWith(".m3u") || full.contains(".m3u8") ||
            full.contains("format=m3u8") || full.contains("type=m3u8") ||
            full.contains("chunklist") || full.contains("/hls/") ||
            full.contains("output=m3u8") || full.contains("output=hls")
        ) {
            return StreamFormat.HLS
        }
        if (path.endsWith(".mpd") || full.contains(".mpd") || full.contains("format=mpd") ||
            (full.contains("/dash/") && !full.contains(".m3u8"))
        ) {
            return StreamFormat.DASH
        }
        if (path.endsWith(".ism") || path.endsWith(".isml") ||
            (path.endsWith("/manifest") && full.contains(".ism"))
        ) {
            return StreamFormat.SMOOTH
        }

        // 2. Si tiene DRM (ClearKey / Widevine) y no es explícitamente HLS, es DASH
        if (hasDrm) {
            return StreamFormat.DASH
        }

        // 3. Extensiones progresivas conocidas
        if (PROGRESSIVE_EXTENSIONS.any { path.endsWith(it) }) {
            return StreamFormat.PROGRESSIVE
        }

        // 4. Prioridad por campo `type` explícito
        when (type?.trim()?.lowercase()) {
            "hls", "m3u8", "m3u"              -> return StreamFormat.HLS
            "dash", "mpd", "clearkey"         -> return StreamFormat.DASH
            "ss", "smooth", "ism", "mss"      -> return StreamFormat.SMOOTH
            "rtsp"                            -> return StreamFormat.RTSP
            "progressive", "mp4", "ts", "mkv",
            "mp3", "aac", "webm", "flv"       -> return StreamFormat.PROGRESSIVE
        }

        return StreamFormat.UNKNOWN
    }

    fun isDash(): Boolean = detectFormat() == StreamFormat.DASH
    fun isHls(): Boolean = detectFormat() == StreamFormat.HLS

    companion object {
        private val PROGRESSIVE_EXTENSIONS = listOf(
            ".mp4", ".m4v", ".mkv", ".webm", ".ts", ".mts", ".mov", ".avi", ".flv",
            ".mp3", ".aac", ".m4a", ".ogg", ".opus", ".flac", ".wav"
        )

        private fun Any?.toStringMap(): Map<String, String> {
            val raw = this as? Map<*, *> ?: return emptyMap()
            return raw.entries.mapNotNull { (k, v) ->
                val ks = k?.toString()?.trim()
                val vs = v?.toString()?.trim()
                if (ks.isNullOrEmpty() || vs == null) null else ks to vs
            }.toMap()
        }

        private fun String?.isHttpUrl(): Boolean =
            this != null && (startsWith("http://", true) || startsWith("https://", true))

        private fun normalizeHeaderKey(key: String): String = when (key.trim().lowercase()) {
            "user-agent", "user_agent", "useragent" -> "User-Agent"
            "referer", "referrer"                   -> "Referer"
            "origin"                                -> "Origin"
            "cookie"                                -> "Cookie"
            "authorization"                         -> "Authorization"
            else                                    -> key.trim()
        }

        /**
         * Extrae posibles cabeceras embebidas tras `|` en URLs M3U/IPTV
         * (ej. `https://host/live.m3u8|Referer=https://host/&User-Agent=Mozilla...`).
         */
        private fun splitPipeHeaders(rawUrl: String): Pair<String, Map<String, String>> {
            val trimmed = rawUrl.trim()
            val pipeIdx = trimmed.indexOf('|')
            if (pipeIdx <= 0) return trimmed to emptyMap()

            val cleanUrl = trimmed.substring(0, pipeIdx).trim()
            val headerPart = trimmed.substring(pipeIdx + 1).trim()
            if (headerPart.isEmpty()) return cleanUrl to emptyMap()

            val parsed = LinkedHashMap<String, String>()
            headerPart.split('&').forEach { pair ->
                val eq = pair.indexOf('=')
                if (eq > 0) {
                    val rawKey = pair.substring(0, eq).trim()
                    val rawVal = pair.substring(eq + 1).trim()
                    val decodedVal = runCatching { URLDecoder.decode(rawVal, "UTF-8") }.getOrDefault(rawVal)
                    if (rawKey.isNotEmpty() && decodedVal.isNotEmpty()) {
                        parsed[normalizeHeaderKey(rawKey)] = decodedVal
                    }
                }
            }
            return cleanUrl to parsed
        }

        fun fromMap(map: Map<*, *>): StreamChannel {
            val name = map["name"]?.toString()?.takeIf { it.isNotBlank() } ?: "Canal"
            val type = map["type"]?.toString()?.takeIf { it.isNotBlank() && it != "null" }
            val icono = (map["icono"] ?: map["logo"] ?: map["logoUrl"])?.toString()
            val rawUrl = (map["original_url"] ?: map["url"])?.toString()?.trim() ?: ""
            val (originalUrl, pipeHeaders) = splitPipeHeaders(rawUrl)

            val drmBlock = map["drm"] as? Map<*, *>
            val rawDrmType = (drmBlock?.get("type") ?: map["drm_type"] ?: map["drmType"])
                ?.toString()?.trim()?.uppercase()

            // ── URL de licencia remota ───────────────────────────────────────
            val rawLicenseUri = map["drm_license_uri"]?.toString()?.trim()
            val licenseUrl = (drmBlock?.get("licenseUrl") ?: map["drm_license_url"]
                ?: map["licenseUrl"])?.toString()?.trim()?.takeIf { it.isNotEmpty() }
                ?: rawLicenseUri?.takeIf { it.isHttpUrl() }

            val licenseHeaders = drmBlock?.get("licenseHeaders").toStringMap()
                .ifEmpty { map["drm_license_headers"].toStringMap() }

            val forceL3 = (drmBlock?.get("forceL3") ?: map["force_l3"])
                ?.toString()?.equals("true", ignoreCase = true) == true

            // ── ClearKey local ───────────────────────────────────────────────
            var clearKeyData: String? = null
            if (!rawLicenseUri.isNullOrBlank() && !rawLicenseUri.isHttpUrl()) {
                clearKeyData = rawLicenseUri
            }
            if (clearKeyData == null) {
                val rawClearkeys = (drmBlock?.get("clearKeys") ?: map["clearkeys"]).toStringMap()
                if (rawClearkeys.isNotEmpty()) {
                    clearKeyData = rawClearkeys.entries
                        .filter { it.key.isNotEmpty() && it.value.isNotEmpty() }
                        .joinToString(",") { "kid:${it.key},k:${it.value}" }
                        .takeIf { it.isNotEmpty() }
                }
            }
            if (clearKeyData == null) {
                val k1 = map["k1"]?.toString()?.trim()
                val k2 = map["k2"]?.toString()?.trim()
                if (!k1.isNullOrBlank() && !k2.isNullOrBlank()) clearKeyData = "kid:$k1,k:$k2"
            }

            // ── Esquema DRM final ────────────────────────────────────────────
            val drmScheme = when {
                rawDrmType == "WIDEVINE" || rawDrmType == "COM.WIDEVINE.ALPHA" ->
                    if (licenseUrl != null) DrmScheme.WIDEVINE else DrmScheme.NONE
                rawDrmType == "PLAYREADY" || rawDrmType == "COM.MICROSOFT.PLAYREADY" ->
                    if (licenseUrl != null) DrmScheme.PLAYREADY else DrmScheme.NONE
                !clearKeyData.isNullOrBlank() -> DrmScheme.CLEARKEY
                rawDrmType == "CLEARKEY" && licenseUrl != null -> DrmScheme.CLEARKEY
                licenseUrl != null && rawDrmType == null -> DrmScheme.WIDEVINE
                else -> DrmScheme.NONE
            }

            // ── Headers HTTP (normalizados) ──────────────────────────────────
            val rawHeaders = map["headers"].toStringMap()
            val headers = LinkedHashMap<String, String>()
            pipeHeaders.forEach { (k, v) ->
                if (v.isNotEmpty()) headers[normalizeHeaderKey(k)] = v
            }
            rawHeaders.forEach { (k, v) ->
                if (v.isNotEmpty()) headers[normalizeHeaderKey(k)] = v
            }
            fun addIfAbsent(key: String, value: Any?) {
                val v = value?.toString()?.trim()
                val norm = normalizeHeaderKey(key)
                if (!v.isNullOrEmpty() && !headers.containsKey(norm)) headers[norm] = v
            }
            addIfAbsent("User-Agent", map["user_agent"] ?: map["userAgent"] ?: map["user-agent"])
            addIfAbsent("Referer", map["referer"] ?: map["referrer"])
            addIfAbsent("Origin", map["origin"])

            return StreamChannel(
                name                = name,
                type                = type,
                icono               = icono,
                originalUrl         = originalUrl,
                drmScheme           = drmScheme,
                clearKeyLicenseData = if (drmScheme == DrmScheme.CLEARKEY) clearKeyData else null,
                licenseUrl          = if (drmScheme == DrmScheme.CLEARKEY && clearKeyData != null) null else licenseUrl,
                licenseHeaders      = licenseHeaders,
                forceWidevineL3     = forceL3,
                headers             = headers,
                globalIndex         = (map["globalIndex"] as? Number)?.toInt(),
                category            = map["category"]?.toString(),
                sourceGroup         = map["source_group"]?.toString(),
                sessionId           = (map["sessionId"] as? Number)?.toInt() ?: 0
            )
        }
    }
}
