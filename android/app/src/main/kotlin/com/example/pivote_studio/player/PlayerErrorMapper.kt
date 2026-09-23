package com.example.pivote_studio.player

import android.net.Uri
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.PlaybackException
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.HttpDataSource
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.drm.ClearKeyParseException

/**
 * Representa información estructurada de error para la capa superior / UI.
 */
data class PlayerErrorInfo(
    val errorCode: String,
    val technicalMessage: String,
    val cause: Throwable? = null
)

/**
 * Mapper y logger seguro de errores para NativeMediaPlayer.
 * Categoriza excepciones de ExoPlayer / DRM / HTTP y sanitiza información sensible en logs.
 */
@OptIn(UnstableApi::class)
object PlayerErrorMapper {

    private const val TAG = "NativePlayerError"

    // Códigos de error estándar solicitados
    const val ERROR_INVALID_URL = "INVALID_URL"
    const val ERROR_MPD_LOAD = "MPD_LOAD_ERROR"
    const val ERROR_HTTP = "HTTP_ERROR"
    const val ERROR_DRM_PARSE = "DRM_PARSE_ERROR"
    const val ERROR_DRM_SESSION = "DRM_SESSION_ERROR"
    const val ERROR_CLEARKEY = "CLEARKEY_ERROR"
    const val ERROR_DECODER = "DECODER_ERROR"
    const val ERROR_NETWORK = "NETWORK_ERROR"
    const val ERROR_SOURCE = "SOURCE_ERROR"
    const val ERROR_UNSUPPORTED_FORMAT = "UNSUPPORTED_FORMAT"

    fun map(error: Throwable): PlayerErrorInfo {
        return when (error) {
            is ClearKeyParseException -> {
                PlayerErrorInfo(
                    errorCode = ERROR_DRM_PARSE,
                    technicalMessage = error.message ?: "Error al parsear claves ClearKey",
                    cause = error
                )
            }
            is PlaybackException -> mapPlaybackException(error)
            is IllegalArgumentException -> {
                PlayerErrorInfo(
                    errorCode = ERROR_INVALID_URL,
                    technicalMessage = error.message ?: "Argumento o URL no válida",
                    cause = error
                )
            }
            else -> {
                PlayerErrorInfo(
                    errorCode = ERROR_SOURCE,
                    technicalMessage = error.message ?: "Error desconocido en el reproductor",
                    cause = error
                )
            }
        }
    }

    private fun mapPlaybackException(e: PlaybackException): PlayerErrorInfo {
        val code = when (e.errorCode) {
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
            PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT -> ERROR_NETWORK

            PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS,
            PlaybackException.ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED -> ERROR_HTTP

            PlaybackException.ERROR_CODE_PARSING_MANIFEST_MALFORMED,
            PlaybackException.ERROR_CODE_PARSING_CONTAINER_MALFORMED,
            PlaybackException.ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED -> ERROR_MPD_LOAD

            PlaybackException.ERROR_CODE_DRM_SYSTEM_ERROR,
            PlaybackException.ERROR_CODE_DRM_PROVISIONING_FAILED,
            PlaybackException.ERROR_CODE_DRM_DEVICE_REVOKED -> ERROR_DRM_SESSION

            PlaybackException.ERROR_CODE_DRM_LICENSE_ACQUISITION_FAILED,
            PlaybackException.ERROR_CODE_DRM_UNSPECIFIED,
            PlaybackException.ERROR_CODE_DRM_SCHEME_UNSUPPORTED -> ERROR_CLEARKEY

            PlaybackException.ERROR_CODE_DECODER_INIT_FAILED,
            PlaybackException.ERROR_CODE_DECODER_QUERY_FAILED,
            PlaybackException.ERROR_CODE_DECODING_FAILED,
            PlaybackException.ERROR_CODE_DECODING_FORMAT_UNSUPPORTED -> ERROR_DECODER

            PlaybackException.ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED -> ERROR_UNSUPPORTED_FORMAT

            else -> {
                val cause = e.cause
                if (cause is HttpDataSource.InvalidResponseCodeException) {
                    ERROR_HTTP
                } else if (cause is HttpDataSource.HttpDataSourceException) {
                    ERROR_NETWORK
                } else {
                    ERROR_SOURCE
                }
            }
        }

        return PlayerErrorInfo(
            errorCode = code,
            technicalMessage = e.message ?: "PlaybackException ($code)",
            cause = e
        )
    }

    /**
     * Imprime en Logcat la traza del error de forma técnica y estrictamente sanitizada.
     */
    fun logError(channel: StreamChannel?, errorInfo: PlayerErrorInfo) {
        val sanitizedUrl = sanitizeUrl(channel?.originalUrl ?: "")
        val drmType = if (channel?.isClearKey() == true) "CLEARKEY" else if (channel?.hasDrm() == true) "DRM_OTHER" else "NONE"

        Log.e(
            TAG,
            """
            ┌────────────────── NATIVE PLAYER ERROR ──────────────────
            │ Channel Name: ${channel?.name ?: "N/A"}
            │ URL:          $sanitizedUrl
            │ Type:         ${channel?.type ?: "N/A"}
            │ DrmType:      $drmType
            │ ErrorCode:    ${errorInfo.errorCode}
            │ Message:      ${errorInfo.technicalMessage}
            │ Exception:    ${errorInfo.cause?.javaClass?.simpleName ?: "None"}
            └─────────────────────────────────────────────────────────
            """.trimIndent(),
            errorInfo.cause
        )
    }

    /**
     * Sanitiza una URL para que los query tokens o firmas no queden expuestos en texto plano.
     */
    fun sanitizeUrl(rawUrl: String): String {
        if (rawUrl.isBlank()) return "empty_url"
        return try {
            val uri = Uri.parse(rawUrl)
            val scheme = uri.scheme ?: "http"
            val host = uri.host ?: ""
            val path = uri.path ?: ""
            val queryParams = uri.queryParameterNames
            if (queryParams.isEmpty()) {
                "$scheme://$host$path"
            } else {
                val safeQuery = queryParams.joinToString("&") { param ->
                    val value = uri.getQueryParameter(param) ?: ""
                    if (param.contains("token", ignoreCase = true) ||
                        param.contains("key", ignoreCase = true) ||
                        param.contains("auth", ignoreCase = true) ||
                        param.contains("sig", ignoreCase = true)
                    ) {
                        "$param=***"
                    } else if (value.length > 20) {
                        "$param=${value.take(4)}...${value.takeLast(4)}"
                    } else {
                        "$param=$value"
                    }
                }
                "$scheme://$host$path?$safeQuery"
            }
        } catch (_: Exception) {
            "${rawUrl.take(30)}..."
        }
    }
}
