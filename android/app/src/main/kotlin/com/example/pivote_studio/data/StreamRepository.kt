package com.example.pivote_studio.data

import org.json.JSONArray
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
        // Convertir JSONObject recursivamente a Map para reutilizar el parser
        // único de StreamChannel, conservando bloques DRM y headers anidados.
        val json = JSONObject(jsonString)
        return StreamChannel.fromMap(json.toKotlinMap())
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

/** Convierte objetos JSON anidados a mapas/listas Kotlin sin perder valores. */
private fun JSONObject.toKotlinMap(): Map<String, Any?> {
    val result = LinkedHashMap<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        result[key] = get(key).toKotlinValue()
    }
    return result
}

private fun JSONArray.toKotlinList(): List<Any?> =
    (0 until length()).map { index -> get(index).toKotlinValue() }

private fun Any?.toKotlinValue(): Any? = when (this) {
    JSONObject.NULL -> null
    is JSONObject -> toKotlinMap()
    is JSONArray -> toKotlinList()
    else -> this
}
