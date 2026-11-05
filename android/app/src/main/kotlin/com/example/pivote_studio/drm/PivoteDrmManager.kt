package com.example.pivote_studio.drm

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.HttpMediaDrmCallback
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Gestor de DRM unificado para Media3 / ExoPlayer.
 *
 * Soporta:
 *   • ClearKey local (W3C JSON) — kid:k pairs o JSON. Se inyecta exclusivamente vía
 *     [DrmSessionManagerProvider] en la factoría del MediaSource, SIN DrmConfiguration
 *     en el MediaItem para evitar que ExoPlayer anule el LocalMediaDrmCallback.
 *   • Widevine Modular (CENC y CBCS) con servidor de licencias remoto vía [HttpMediaDrmCallback].
 */
@OptIn(UnstableApi::class)
object PivoteDrmManager {

    private const val TAG = "PivoteDrmManager"

    /**
     * Construye la [MediaItem.DrmConfiguration] sólo para esquemas remotos como Widevine.
     * Para ClearKey local retorna null para que la factoría maneje la sesión con las claves en memoria.
     */
    fun buildDrmConfiguration(channel: StreamChannel): MediaItem.DrmConfiguration? {
        return when (channel.drmScheme) {
            DrmScheme.WIDEVINE -> buildWidevineConfig(channel)
            else               -> null
        }
    }

    /**
     * Construye el [DrmSessionManager] para insertar en el MediaSource.
     */
    fun buildDrmSessionManager(
        channel: StreamChannel,
        httpFactory: DataSource.Factory
    ): DrmSessionManager? {
        return when (channel.drmScheme) {

            DrmScheme.CLEARKEY -> {
                val data = channel.clearKeyLicenseData
                if (data.isNullOrBlank()) return null
                try {
                    val keys = ClearKeyParser.parse(data)
                    Log.d(TAG, "ClearKey DRM: ${keys.size} key(s) parseadas con éxito.")
                    ClearKeyManager.createDrmSessionManager(keys)
                } catch (e: Exception) {
                    Log.e(TAG, "Error al crear ClearKey DrmSessionManager: ${e.message}", e)
                    null
                }
            }

            DrmScheme.WIDEVINE -> {
                val licenseUrl = channel.widevineLicenseUrl ?: return null
                Log.d(TAG, "Widevine DRM configurado con licenseUrl=$licenseUrl")
                val drmHttpFactory = StreamHttpDataSourceFactory.create(
                    channel.widevineLicenseHeaders.ifEmpty { channel.headers },
                    requestUrl = licenseUrl
                )
                val drmCallback = HttpMediaDrmCallback(licenseUrl, drmHttpFactory)
                channel.widevineLicenseHeaders.forEach { (k, v) ->
                    drmCallback.setKeyRequestProperty(k, v)
                }
                DefaultDrmSessionManager.Builder()
                    .setUuidAndExoMediaDrmProvider(
                        C.WIDEVINE_UUID,
                        FrameworkMediaDrm.DEFAULT_PROVIDER
                    )
                    .setMultiSession(true)
                    .build(drmCallback)
            }

            DrmScheme.NONE -> null
        }
    }

    private fun buildWidevineConfig(channel: StreamChannel): MediaItem.DrmConfiguration? {
        val licenseUrl = channel.widevineLicenseUrl ?: return null

        return MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
            .setLicenseUri(licenseUrl)
            .setMultiSession(true)
            .apply {
                if (channel.widevineLicenseHeaders.isNotEmpty()) {
                    setLicenseRequestHeaders(channel.widevineLicenseHeaders)
                }
            }
            .build()
    }
}
