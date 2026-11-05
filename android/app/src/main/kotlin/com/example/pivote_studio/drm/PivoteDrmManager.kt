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
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Gestor de DRM unificado para Media3 / ExoPlayer.
 *
 * Soporta:
 *   • ClearKey estático (W3C JSON local) — kid:key pairs, JSON array o JSON object.
 *   • Widevine Modular con servidor de licencias remoto (CENC y CBCS).
 *
 * No realiza nunca peticiones HTTP para ClearKey: todas las claves se suministran
 * localmente a través de [LocalMediaDrmCallback].
 */
@OptIn(UnstableApi::class)
object PivoteDrmManager {

    private const val TAG = "PivoteDrmManager"

    /**
     * Construye la [MediaItem.DrmConfiguration] apropiada para el canal.
     * Retorna null si el canal no tiene DRM.
     */
    fun buildDrmConfiguration(channel: StreamChannel): MediaItem.DrmConfiguration? {
        return when (channel.drmScheme) {
            DrmScheme.CLEARKEY  -> buildClearKeyConfig()
            DrmScheme.WIDEVINE  -> buildWidevineConfig(channel)
            DrmScheme.NONE      -> null
        }
    }

    /**
     * Construye el [DrmSessionManager] para insertar en el MediaSource.
     * Se necesita cuando la DrmConfiguration del MediaItem no es suficiente
     * (ClearKey multi-session con claves locales).
     */
    fun buildDrmSessionManager(
        channel: StreamChannel,
        httpFactory: DataSource.Factory
    ): DrmSessionManager {
        return when (channel.drmScheme) {

            DrmScheme.CLEARKEY -> {
                val keys = ClearKeyParser.parse(channel.clearKeyLicenseData)
                val json = ClearKeyManager.buildClearKeyJson(keys)
                Log.d(TAG, "ClearKey DRM: ${keys.size} key(s) configuradas.")
                DefaultDrmSessionManager.Builder()
                    .setUuidAndExoMediaDrmProvider(
                        C.CLEARKEY_UUID,
                        FrameworkMediaDrm.DEFAULT_PROVIDER
                    )
                    .setMultiSession(true)
                    .setPlayClearSamplesWithoutKeys(true)
                    .build(LocalMediaDrmCallback(json.toByteArray(Charsets.UTF_8)))
            }

            DrmScheme.WIDEVINE -> {
                val licenseUrl = requireNotNull(channel.widevineLicenseUrl) {
                    "Se requiere widevineLicenseUrl para DRM Widevine"
                }
                Log.d(TAG, "Widevine DRM: licenseUrl configurada.")
                val drmHttpFactory = StreamHttpDataSourceFactory.create(
                    channel.widevineLicenseHeaders.ifEmpty { channel.headers }
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

            DrmScheme.NONE -> DrmSessionManager.DRM_UNSUPPORTED
        }
    }

    // ── Helpers privados ────────────────────────────────────────────────────────

    private fun buildClearKeyConfig(): MediaItem.DrmConfiguration =
        MediaItem.DrmConfiguration.Builder(C.CLEARKEY_UUID)
            .setMultiSession(true)
            .build()

    private fun buildWidevineConfig(channel: StreamChannel): MediaItem.DrmConfiguration {
        val licenseUrl = channel.widevineLicenseUrl
            ?: error("Se requiere widevineLicenseUrl para DRM Widevine")

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

