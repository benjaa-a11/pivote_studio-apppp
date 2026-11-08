package com.example.pivote_studio.player

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.ParserException
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.HttpDataSource
import androidx.media3.exoplayer.source.UnrecognizedInputFormatException
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.drm.ClearKeyParseException

/**
 * Representa información estructurada y tipada de error para la capa Dart y el motor de failover.
 */
data class PlayerErrorInfo(
    val errorCode: String,
    val technicalMessage: String,
    val cause: Throwable? = null,
    val mediaErrorCode: Int = -1,
    val httpStatus: Int = -1
) {
    val userMessage: String get() = PlayerErrorMapper.userMessage(errorCode, httpStatus)
}

/**
 * Clasificador tipado de errores de Media3 ExoPlayer (red, HTTP 401/403/404, manifiesto,
 * decoder, DRM, ventana en vivo y pista de video sin frames).
 *
 * Imprime logs técnicos sanitizados únicamente en compilaciones DEBUG.
 */
@OptIn(UnstableApi::class)
object PlayerErrorMapper {

    private const val SUBTAG = "ErrorMapper"

    const val ERROR_INVALID_URL        = "INVALID_URL"
    const val ERROR_MPD_LOAD           = "MPD_LOAD_ERROR"
    const val ERROR_MANIFEST           = "MANIFEST_ERROR"
    const val ERROR_HTTP               = "HTTP_ERROR"
    const val ERROR_DRM_PARSE          = "DRM_PARSE_ERROR"
    const val ERROR_DRM_SESSION        = "DRM_SESSION_ERROR"
    const val ERROR_DRM_LICENSE        = "DRM_LICENSE_ERROR"
    const val ERROR_DRM_UNSUPPORTED    = "DRM_UNSUPPORTED"
    const val ERROR_CLEARKEY           = "CLEARKEY_ERROR"
    const val ERROR_DECODER            = "DECODER_ERROR"
    const val ERROR_NETWORK            = "NETWORK_ERROR"
    const val ERROR_BEHIND_LIVE_WINDOW = "BEHIND_LIVE_WINDOW"
    const val ERROR_SOURCE             = "SOURCE_ERROR"
    const val ERROR_UNSUPPORTED_FORMAT = "UNSUPPORTED_FORMAT"
    const val ERROR_AUDIO_ONLY         = "AUDIO_ONLY_NO_VIDEO"

    fun map(error: Throwable): PlayerErrorInfo = when (error) {
        is ClearKeyParseException -> PlayerErrorInfo(
            ERROR_DRM_PARSE, error.message ?: "Error al parsear claves ClearKey", error
        )
        is PlaybackException -> mapPlaybackException(error)
        is IllegalArgumentException -> PlayerErrorInfo(
            ERROR_INVALID_URL, error.message ?: "Argumento o URL no válida", error
        )
        else -> PlayerErrorInfo(
            ERROR_SOURCE, error.message ?: "Error desconocido en el reproductor", error
        )
    }

    private fun mapPlaybackException(e: PlaybackException): PlayerErrorInfo {
        val http = findCause<HttpDataSource.InvalidResponseCodeException>(e)

        val code = when (e.errorCode) {
            PlaybackException.ERROR_CODE_BEHIND_LIVE_WINDOW -> ERROR_BEHIND_LIVE_WINDOW

            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT,
            PlaybackException.ERROR_CODE_IO_UNSPECIFIED,
            PlaybackException.ERROR_CODE_TIMEOUT -> ERROR_NETWORK

            PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS,
            PlaybackException.ERROR_CODE_IO_FILE_NOT_FOUND,
            PlaybackException.ERROR_CODE_IO_NO_PERMISSION,
            PlaybackException.ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE,
            PlaybackException.ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED -> ERROR_HTTP

            PlaybackException.ERROR_CODE_PARSING_MANIFEST_MALFORMED,
            PlaybackException.ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED -> ERROR_MANIFEST

            PlaybackException.ERROR_CODE_PARSING_CONTAINER_MALFORMED,
            PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED -> ERROR_UNSUPPORTED_FORMAT

            PlaybackException.ERROR_CODE_DRM_SCHEME_UNSUPPORTED -> ERROR_DRM_UNSUPPORTED

            PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED,
            PlaybackException.ERROR_CODE_DRM_LICENSE_EXPIRED,
            PlaybackException.ERROR_CODE_DRM_DISALLOWED_OPERATION -> ERROR_DRM_LICENSE

            PlaybackException.ERROR_CODE_DRM_SYSTEM_ERROR,
            PlaybackException.ERROR_CODE_DRM_PROVISIONING_FAILED,
            PlaybackException.ERROR_CODE_DRM_DEVICE_REVOKED,
            PlaybackException.ERROR_CODE_DRM_CONTENT_ERROR,
            PlaybackException.ERROR_CODE_DRM_UNSPECIFIED -> ERROR_DRM_SESSION

            PlaybackException.ERROR_CODE_DECODER_INIT_FAILED,
            PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED,
            PlaybackException.ERROR_CODE_DECODING_FAILED,
            PlaybackException.ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES,
            PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED,
            PlaybackException.ERROR_CODE_AUDIO_TRACK_INIT_FAILED,
            PlaybackException.ERROR_CODE_AUDIO_TRACK_WRITE_FAILED -> ERROR_DECODER

            else -> when {
                http != null -> ERROR_HTTP
                findCause<UnrecognizedInputFormatException>(e) != null -> ERROR_UNSUPPORTED_FORMAT
                findCause<ParserException>(e) != null -> ERROR_MANIFEST
                findCause<HttpDataSource.HttpDataSourceException>(e) != null -> ERROR_NETWORK
                else -> ERROR_SOURCE
            }
        }

        val detail = buildString {
            append(e.errorCodeName)
            http?.let { append(" · HTTP ${it.responseCode}") }
            e.cause?.message?.takeIf { it.isNotBlank() }?.let { append(" · ").append(it.take(160)) }
        }

        return PlayerErrorInfo(
            errorCode = code,
            technicalMessage = detail,
            cause = e,
            mediaErrorCode = e.errorCode,
            httpStatus = http?.responseCode ?: -1
        )
    }

    /** Errores que justifican probar el siguiente formato de contenedor (DASH → HLS → TS). */
    fun isFormatMismatch(info: PlayerErrorInfo): Boolean =
        info.errorCode == ERROR_MANIFEST || info.errorCode == ERROR_UNSUPPORTED_FORMAT ||
            info.errorCode == ERROR_MPD_LOAD

    /** Errores transitorios de red o de servidor que merecen backoff exponencial en el mismo origen. */
    fun isTransientNetwork(info: PlayerErrorInfo): Boolean =
        info.errorCode == ERROR_NETWORK ||
            (info.errorCode == ERROR_HTTP && info.httpStatus in setOf(408, 429, 500, 502, 503, 504))

    /** Errores HTTP que sugieren token expirado o bloqueo de IP/CORS (401, 403, 404, 410). */
    fun isTokenOrAccessError(info: PlayerErrorInfo): Boolean =
        info.errorCode == ERROR_HTTP && info.httpStatus in setOf(401, 403, 404, 410)

    fun isDrmError(info: PlayerErrorInfo): Boolean =
        info.errorCode == ERROR_DRM_SESSION || info.errorCode == ERROR_DRM_LICENSE ||
            info.errorCode == ERROR_CLEARKEY

    fun userMessage(code: String, httpStatus: Int): String = when (code) {
        ERROR_NETWORK -> "Sin conexión con el servidor"
        ERROR_HTTP -> when (httpStatus) {
            401, 403 -> "Acceso denegado o token vencido ($httpStatus)"
            404, 410 -> "Transmisión no encontrada ($httpStatus)"
            -1 -> "El servidor rechazó la conexión"
            else -> "Error del servidor ($httpStatus)"
        }
        ERROR_MANIFEST, ERROR_MPD_LOAD -> "Manifiesto de la transmisión inválido"
        ERROR_UNSUPPORTED_FORMAT -> "Formato de transmisión no soportado"
        ERROR_DRM_PARSE -> "Claves de cifrado inválidas"
        ERROR_DRM_LICENSE -> "No se pudo obtener la licencia DRM"
        ERROR_DRM_SESSION, ERROR_CLEARKEY -> "Error de descifrado DRM"
        ERROR_DRM_UNSUPPORTED -> "El dispositivo no soporta este DRM"
        ERROR_DECODER -> "El dispositivo no puede decodificar este video"
        ERROR_AUDIO_ONLY -> "El canal envió audio sin imagen de video"
        ERROR_INVALID_URL -> "Enlace de transmisión inválido"
        else -> "Error de reproducción"
    }

    private inline fun <reified T : Throwable> findCause(e: Throwable): T? {
        var c: Throwable? = e
        var depth = 0
        while (c != null && depth < 10) {
            if (c is T) return c
            c = c.cause
            depth++
        }
        return null
    }

    fun logError(channel: StreamChannel?, errorInfo: PlayerErrorInfo) {
        NativePlayerConfig.logE(
            SUBTAG,
            """
            ┌────────────────── NATIVE PLAYER ERROR ──────────────────
            │ Channel Name: ${channel?.name ?: "N/A"}
            │ URL:          ${sanitizeUrl(channel?.originalUrl ?: "")}
            │ Type:         ${channel?.type ?: "N/A"} (format=${channel?.detectFormat() ?: "N/A"})
            │ DrmType:      ${channel?.drmScheme?.name ?: "NONE"} (${channel?.encryptionScheme?.name ?: "AUTO"})
            │ ErrorCode:    ${errorInfo.errorCode} (media3=${errorInfo.mediaErrorCode}, http=${errorInfo.httpStatus})
            │ Message:      ${errorInfo.technicalMessage}
            │ Exception:    ${errorInfo.cause?.javaClass?.simpleName ?: "None"}
            └─────────────────────────────────────────────────────────
            """.trimIndent(),
            errorInfo.cause
        )
    }

    fun sanitizeUrl(rawUrl: String): String {
        if (rawUrl.isBlank()) return "empty_url"
        return try {
            val uri = Uri.parse(rawUrl)
            val base = "${uri.scheme ?: "http"}://${uri.host ?: ""}${uri.path ?: ""}"
            val params = uri.queryParameterNames
            if (params.isEmpty()) base else base + "?" + params.joinToString("&") { p ->
                val v = uri.getQueryParameter(p) ?: ""
                when {
                    listOf("token", "key", "auth", "sig", "hash", "pass", "hdnea").any { p.contains(it, true) } -> "$p=***"
                    v.length > 20 -> "$p=${v.take(4)}...${v.takeLast(4)}"
                    else -> "$p=$v"
                }
            }
        } catch (_: Exception) {
            "${rawUrl.take(30)}..."
        }
    }
}
