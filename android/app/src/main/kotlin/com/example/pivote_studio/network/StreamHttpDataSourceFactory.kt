package com.example.pivote_studio.network

import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource

/**
 * Fábrica de DataSources HTTP para Media3 ExoPlayer.
 * Aplica headers HTTP dinámicos específicos por canal (Origin, Referer, User-Agent, etc.)
 * y configura tiempos de espera adecuados para streaming en vivo.
 */
@OptIn(UnstableApi::class)
object StreamHttpDataSourceFactory {

    private const val DEFAULT_USER_AGENT = "Mozilla/5.0 (Linux; Android 14; Mobile) " +
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36 PivotePlayer/1.0"

    private const val DEFAULT_CONNECT_TIMEOUT_MS = 12_000
    private const val DEFAULT_READ_TIMEOUT_MS = 12_000

    /**
     * Crea un DataSource.Factory configurado con los headers provistos por el canal.
     */
    fun create(headers: Map<String, String>): DataSource.Factory {
        // Extraer User-Agent si viene especificado en los headers (case-insensitive)
        val userAgentEntry = headers.entries.firstOrNull {
            it.key.equals("user-agent", ignoreCase = true)
        }
        val userAgent = userAgentEntry?.value ?: DEFAULT_USER_AGENT

        val factory = DefaultHttpDataSource.Factory()
            .setUserAgent(userAgent)
            .setConnectTimeoutMs(DEFAULT_CONNECT_TIMEOUT_MS)
            .setReadTimeoutMs(DEFAULT_READ_TIMEOUT_MS)
            .setAllowCrossProtocolRedirects(true)
            .setKeepPostFor302Redirects(true)

        if (headers.isNotEmpty()) {
            factory.setDefaultRequestProperties(headers)
        }

        return factory
    }
}
