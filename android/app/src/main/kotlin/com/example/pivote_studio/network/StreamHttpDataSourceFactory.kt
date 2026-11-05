package com.example.pivote_studio.network

import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultHttpDataSource

/**
 * Fábrica de DataSources HTTP para Media3 ExoPlayer.
 * Aplica headers HTTP dinámicos específicos por canal (Origin, Referer, User-Agent, etc.)
 * y tiempos de espera adecuados para streaming en vivo.
 */
@OptIn(UnstableApi::class)
object StreamHttpDataSourceFactory {

    private const val DEFAULT_USER_AGENT =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

    private const val DEFAULT_CONNECT_TIMEOUT_MS = 8_000
    private const val DEFAULT_READ_TIMEOUT_MS = 8_000

    /**
     * Crea un DataSource.Factory configurado con los headers provistos por el canal.
     */
    fun create(headers: Map<String, String>, requestUrl: String = ""): DataSource.Factory {
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

        val mergedHeaders = headers.filterKeys { !it.equals("user-agent", ignoreCase = true) }.toMutableMap()

        // Auto-inyectar headers para CDN de Flow / CVAA si no vienen definidos
        if (requestUrl.contains("cvattv.com.ar", ignoreCase = true) || requestUrl.contains("flow.com.ar", ignoreCase = true)) {
            if (!mergedHeaders.keys.any { it.equals("origin", ignoreCase = true) }) {
                mergedHeaders["Origin"] = "https://web.flow.com.ar"
            }
            if (!mergedHeaders.keys.any { it.equals("referer", ignoreCase = true) }) {
                mergedHeaders["Referer"] = "https://web.flow.com.ar/"
            }
        }

        if (mergedHeaders.isNotEmpty()) {
            factory.setDefaultRequestProperties(mergedHeaders)
        }

        return factory
    }
}
