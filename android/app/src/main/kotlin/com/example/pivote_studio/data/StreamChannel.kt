package com.example.pivote_studio.data

/**
 * Tipo de DRM que se va a usar para descifrar el stream.
 */
enum class DrmScheme { NONE, CLEARKEY, WIDEVINE }

/**
 * Modelo de datos inmutable para canales de streaming de TV, radio y VOD.
 * Compatible con HLS (m3u8), MPEG-DASH (mpd), HTTP progresivo (mp4),
 * ClearKey DRM (local W3C JSON), Widevine Modular (CENC / CBCS) y
 * headers HTTP personalizados por canal.
 */
data class StreamChannel(
    val name: String,
    val type: String? = null,         // "hls" | "dash" | "progressive" | "clearkey" | null
    val icono: String? = null,
    val originalUrl: String,

    // ── DRM ─────────────────────────────────────────────────────────────────
    val drmScheme: DrmScheme = DrmScheme.NONE,

    /** ClearKey: cadena "kid:XXX,k:YYY" o JSON W3C. No puede ser una URL HTTP. */
    val clearKeyLicenseData: String? = null,

    /** Widevine: URL del servidor de licencias (https://…). */
    val widevineLicenseUrl: String? = null,

    /** Headers adicionales para la solicitud de licencia Widevine. */
    val widevineLicenseHeaders: Map<String, String> = emptyMap(),

    // ── HTTP ─────────────────────────────────────────────────────────────────
    val headers: Map<String, String> = emptyMap(),

    // ── Metadatos ────────────────────────────────────────────────────────────
    val globalIndex: Int? = null,
    val category: String? = null,
    val sourceGroup: String? = null
) {

    fun isDash(): Boolean {
        val u = originalUrl.lowercase()
        val t = type?.trim()?.uppercase()
        return u.contains(".mpd") ||
               t == "DASH" || t == "MPD" || t == "CLEARKEY" ||
               drmScheme == DrmScheme.CLEARKEY ||
               drmScheme == DrmScheme.WIDEVINE
    }

    fun isHls(): Boolean {
        val u = originalUrl.lowercase()
        val t = type?.trim()?.lowercase()
        return u.contains(".m3u8") || u.contains("m3u") || t == "hls"
    }

    companion object {
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<*, *>): StreamChannel {
            val name       = map["name"]?.toString() ?: "Canal"
            val type       = map["type"]?.toString()
            val icono      = (map["icono"] ?: map["logo"] ?: map["logoUrl"])?.toString()
            val originalUrl = (map["original_url"] ?: map["url"])?.toString() ?: ""

            // ── Widevine ────────────────────────────────────────────────────
            val rawDrmBlock = map["drm"] as? Map<*, *>
            val rawDrmType  = rawDrmBlock?.get("type")?.toString()?.uppercase()
                ?: map["drm_type"]?.toString()?.uppercase()

            val widevineLicenseUrl: String?
            val widevineLicenseHeaders: Map<String, String>
            if (rawDrmType == "WIDEVINE") {
                widevineLicenseUrl = (rawDrmBlock?.get("licenseUrl")
                    ?: map["drm_license_url"])?.toString()
                val rawLicHdrs = rawDrmBlock?.get("licenseHeaders") as? Map<*, *>
                widevineLicenseHeaders = rawLicHdrs?.entries
                    ?.mapNotNull { (k, v) ->
                        if (k != null && v != null) k.toString() to v.toString() else null
                    }?.toMap() ?: emptyMap()
            } else {
                widevineLicenseUrl    = null
                widevineLicenseHeaders = emptyMap()
            }

            // ── ClearKey ─────────────────────────────────────────────────────
            var clearKeyData = map["drm_license_uri"]?.toString()?.trim()
            val isHttpUri = clearKeyData?.startsWith("http", ignoreCase = true) == true

            val rawClearkeys = (rawDrmBlock?.get("clearKeys") ?: map["clearkeys"]) as? Map<*, *>
            if (rawClearkeys != null && rawClearkeys.isNotEmpty()) {
                val pairs = rawClearkeys.entries.mapNotNull { (k, v) ->
                    val kStr = k?.toString()?.trim()
                    val vStr = v?.toString()?.trim()
                    if (!kStr.isNullOrEmpty() && !vStr.isNullOrEmpty()) "kid:$kStr,k:$vStr" else null
                }
                if (pairs.isNotEmpty()) clearKeyData = pairs.joinToString(",")
            } else if (isHttpUri) {
                clearKeyData = null       // URL HTTP no válida para LocalMediaDrmCallback
            } else if (clearKeyData.isNullOrBlank()) {
                val k1 = map["k1"]?.toString()?.trim()
                val k2 = map["k2"]?.toString()?.trim()
                if (!k1.isNullOrBlank() && !k2.isNullOrBlank()) clearKeyData = "kid:$k1,k:$k2"
            }

            // ── Esquema DRM final ─────────────────────────────────────────────
            val drmScheme = when {
                rawDrmType == "WIDEVINE"    -> DrmScheme.WIDEVINE
                !clearKeyData.isNullOrBlank() -> DrmScheme.CLEARKEY
                else                          -> DrmScheme.NONE
            }

            // ── Headers HTTP ──────────────────────────────────────────────────
            val rawHeaders = map["headers"] as? Map<*, *>
            val headers = mutableMapOf<String, String>()
            rawHeaders?.forEach { (k, v) ->
                if (k != null && v != null) headers[k.toString()] = v.toString()
            }

            return StreamChannel(
                name                   = name,
                type                   = type,
                icono                  = icono,
                originalUrl            = originalUrl,
                drmScheme              = drmScheme,
                clearKeyLicenseData    = clearKeyData,
                widevineLicenseUrl     = widevineLicenseUrl,
                widevineLicenseHeaders = widevineLicenseHeaders,
                headers                = headers,
                globalIndex            = (map["globalIndex"] as? Number)?.toInt(),
                category               = map["category"]?.toString(),
                sourceGroup            = map["source_group"]?.toString()
            )
        }
    }
}
