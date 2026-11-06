package com.example.pivote_studio.network

import android.content.Context
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import java.net.CookieHandler
import java.net.CookieManager
import java.net.CookiePolicy

/**
 * Fábrica de DataSources HTTP para Media3 ExoPlayer.
 *
 *   • Headers dinámicos por canal (User-Agent, Referer, Origin, Cookie, Authorization…)
 *   • Redirecciones cross-protocol (http ⇄ https), habituales en CDNs IPTV
 *   • Cookies persistentes en memoria (tokens de sesión devueltos por el servidor)
 *   • Soporte de esquemas locales (file://, content://, asset://) vía [DefaultDataSource]
 */
@OptIn(UnstableApi::class)
object StreamHttpDataSourceFactory {

    const val DEFAULT_USER_AGENT =
        "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) " +
            "Chrome/130.0.0.0 Mobile Safari/537.36"

    private const val CONNECT_TIMEOUT_MS = 12_000
    private const val READ_TIMEOUT_MS    = 15_000

    init {
        // Muchos orígenes IPTV entregan cookies de sesión en el manifiesto que luego
        // exigen en los segmentos. HttpURLConnection las gestiona si hay CookieHandler.
        if (CookieHandler.getDefault() == null) {
            CookieHandler.setDefault(CookieManager(null, CookiePolicy.ACCEPT_ORIGINAL_SERVER))
        }
    }

    /**
     * Crea un [DefaultHttpDataSource.Factory] configurado con los headers del canal.
     */
    fun createHttp(headers: Map<String, String>, requestUrl: String = ""): DefaultHttpDataSource.Factory {
        val userAgent = headers.entries
            .firstOrNull { it.key.equals("user-agent", ignoreCase = true) }
            ?.value?.takeIf { it.isNotBlank() }
            ?: DEFAULT_USER_AGENT

        val merged = headers
            .filterKeys { !it.equals("user-agent", ignoreCase = true) }
            .toMutableMap()

        // Auto-inyectar headers para CDN de Flow / CVAA si no vienen definidos
        if (requestUrl.contains("cvattv.com.ar", true) || requestUrl.contains("flow.com.ar", true)) {
            if (merged.keys.none { it.equals("origin", true) }) merged["Origin"] = "https://web.flow.com.ar"
            if (merged.keys.none { it.equals("referer", true) }) merged["Referer"] = "https://web.flow.com.ar/"
        }

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
