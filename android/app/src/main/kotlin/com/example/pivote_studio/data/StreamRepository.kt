package com.example.pivote_studio.data

import org.json.JSONObject

/**
 * Repositorio para la gestión y parseo de canales de streaming.
 */
interface StreamRepository {
    fun parseChannel(jsonString: String): StreamChannel
    fun parseChannel(map: Map<*, *>): StreamChannel
    fun getSampleChannel(): StreamChannel
}

class DefaultStreamRepository : StreamRepository {

    override fun parseChannel(jsonString: String): StreamChannel {
        val json = JSONObject(jsonString)
        val headersMap = mutableMapOf<String, String>()
        if (json.has("headers")) {
            val h = json.getJSONObject("headers")
            val keys = h.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                headersMap[key] = h.optString(key, "")
            }
        }

        return StreamChannel(
            name = json.optString("name", "Desconocido"),
            type = json.optString("type", null),
            icono = json.optString("icono", null),
            originalUrl = json.optString("original_url", json.optString("url", "")),
            drmLicenseUri = json.optString("drm_license_uri", null),
            headers = headersMap,
            globalIndex = if (json.has("globalIndex")) json.getInt("globalIndex") else null,
            category = json.optString("category", null),
            sourceGroup = json.optString("source_group", null)
        )
    }

    override fun parseChannel(map: Map<*, *>): StreamChannel {
        return StreamChannel.fromMap(map)
    }

    override fun getSampleChannel(): StreamChannel {
        return StreamChannel(
            name = "FOX Sports 2",
            type = "CLEARKEY",
            icono = null,
            originalUrl = "https://example.com/channel.mpd",
            drmLicenseUri = "kid:BASE64URL_KID,k:BASE64URL_KEY",
            headers = mapOf(
                "Origin" to "https://example.com",
                "Referer" to "https://example.com/",
                "User-Agent" to "Mozilla/5.0"
            ),
            globalIndex = 134,
            category = "DEPORTE",
            sourceGroup = "samples"
        )
    }
}
