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
        // Usar el mismo parser que los mapas evita mantener dos modelos DRM
        // distintos y garantiza compatibilidad con ClearKey y Widevine.
        val json = JSONObject(jsonString)
        return StreamChannel.fromMap(json.toMap())
    }

    override fun parseChannel(map: Map<*, *>): StreamChannel {
        return StreamChannel.fromMap(map)
    }

    override fun getSampleChannel(): StreamChannel {
        return StreamChannel(
            name = "FOX Sports 2",
            type = "DASH",
            icono = null,
            originalUrl = "https://example.com/channel.mpd",
            drmScheme = DrmScheme.CLEARKEY,
            clearKeyLicenseData = "kid:BASE64URL_KID,k:BASE64URL_KEY",
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
