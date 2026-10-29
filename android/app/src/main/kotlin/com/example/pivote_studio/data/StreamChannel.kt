package com.example.pivote_studio.data

/**
 * Modelo de datos inmutable para canales de streaming de TV y eventos en vivo.
 * Compatible con MPEG-DASH, ClearKey DRM y streams autorizados.
 */
data class StreamChannel(
    val name: String,
    val type: String? = null,
    val icono: String? = null,
    val originalUrl: String,
    val drmLicenseUri: String? = null,
    val headers: Map<String, String> = emptyMap(),
    val globalIndex: Int? = null,
    val category: String? = null,
    val sourceGroup: String? = null
) {
    /**
     * Determina si el canal requiere descifrado ClearKey DRM.
     */
    fun isClearKey(): Boolean {
        val t = type?.trim()?.uppercase()
        if (t == "CLEARKEY" || t == "DRM") return true
        val uri = drmLicenseUri?.trim() ?: return false
        return uri.contains("kid", ignoreCase = true) ||
               uri.contains("keys", ignoreCase = true) ||
               uri.startsWith("{")
    }

    /**
     * Determina si el stream corresponde a MPEG-DASH (.mpd).
     */
    fun isDash(): Boolean {
        val u = originalUrl.lowercase()
        val t = type?.trim()?.uppercase()
        return u.contains(".mpd") || t == "DASH" || t == "CLEARKEY" || isClearKey()
    }

    /**
     * Comprueba si tiene claves o configuración DRM válida.
     */
    fun hasDrm(): Boolean {
        return !drmLicenseUri.isNullOrBlank()
    }

    companion object {
        /**
         * Construye un StreamChannel a partir de un Map (típicamente recibido de Flutter o deserializado de JSON).
         */
        @Suppress("UNCHECKED_CAST")
        fun fromMap(map: Map<*, *>): StreamChannel {
            val name = map["name"]?.toString() ?: "Canal"
            val type = map["type"]?.toString()
            val icono = (map["icono"] ?: map["logo"] ?: map["logoUrl"])?.toString()

            // original_url o url
            val originalUrl = (map["original_url"] ?: map["url"])?.toString() ?: ""

            // drm_license_uri puede venir explícito o reconstruirse desde clearkeys / k1/k2
            var drmLicenseUri = map["drm_license_uri"]?.toString()?.trim()

            val isRemoteHttpUrl = drmLicenseUri?.startsWith("http://", ignoreCase = true) == true ||
                                  drmLicenseUri?.startsWith("https://", ignoreCase = true) == true

            // Procesar clearkeys explícitos recibidos desde Flutter (Map) con máxima prioridad
            val rawClearkeys = map["clearkeys"] as? Map<*, *>
            if (rawClearkeys != null && rawClearkeys.isNotEmpty()) {
                val pairs = rawClearkeys.entries.mapNotNull { (k, v) ->
                    val kStr = k?.toString()?.trim()
                    val vStr = v?.toString()?.trim()
                    if (!kStr.isNullOrEmpty() && !vStr.isNullOrEmpty()) "kid:$kStr,k:$vStr" else null
                }
                if (pairs.isNotEmpty()) {
                    drmLicenseUri = pairs.joinToString(",")
                }
            } else if (isRemoteHttpUrl) {
                // Si drm_license_uri es una URL HTTP y no vinieron claves locales en clearkeys,
                // no podemos pasársela a LocalMediaDrmCallback como claves porque fallará.
                drmLicenseUri = null
            } else if (drmLicenseUri.isNullOrBlank()) {
                val k1 = map["k1"]?.toString()?.trim()
                val k2 = map["k2"]?.toString()?.trim()
                if (!k1.isNullOrBlank() && !k2.isNullOrBlank()) {
                    drmLicenseUri = "kid:$k1,k:$k2"
                }
            }

            // Headers
            val rawHeaders = map["headers"] as? Map<*, *>
            val headers = mutableMapOf<String, String>()
            rawHeaders?.forEach { (k, v) ->
                if (k != null && v != null) {
                    headers[k.toString()] = v.toString()
                }
            }

            val globalIndex = (map["globalIndex"] as? Number)?.toInt()
            val category = map["category"]?.toString()
            val sourceGroup = map["source_group"]?.toString()

            return StreamChannel(
                name = name,
                type = type,
                icono = icono,
                originalUrl = originalUrl,
                drmLicenseUri = drmLicenseUri,
                headers = headers,
                globalIndex = globalIndex,
                category = category,
                sourceGroup = sourceGroup
            )
        }
    }
}
