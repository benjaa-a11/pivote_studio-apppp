package com.example.pivote_studio.drm

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.DummyExoMediaDrm
import androidx.media3.exoplayer.drm.ExoMediaDrm
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.HttpMediaDrmCallback
import androidx.media3.exoplayer.drm.UnsupportedDrmException
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import java.util.UUID

/**
 * Gestor de DRM unificado para Media3 / ExoPlayer.
 *
 * Todos los esquemas se inyectan EXCLUSIVAMENTE vía DrmSessionManagerProvider en la
 * factoría del MediaSource (nunca vía MediaItem.DrmConfiguration), lo que da control
 * total sobre headers, nivel de seguridad y callbacks locales.
 *
 * Soporta:
 *   • ClearKey local (kid:k / JSON W3C) → [LocalMediaDrmCallback]
 *   • ClearKey remoto (servidor de licencias W3C) → [HttpMediaDrmCallback]
 *   • Widevine Modular (CENC y CBCS) con headers propios y modo L3 forzado opcional
 *   • PlayReady (dispositivos que lo soporten, p. ej. Android TV)
 */
@OptIn(UnstableApi::class)
object PivoteDrmManager {

    private const val TAG = "PivoteDrmManager"

    /** Comprueba si el dispositivo soporta el esquema indicado. */
    fun isSchemeSupported(uuid: UUID): Boolean =
        runCatching { android.media.MediaDrm.isCryptoSchemeSupported(uuid) }.getOrDefault(false)

    /** Nivel de seguridad Widevine del dispositivo ("L1", "L3" o null si no hay Widevine). */
    val widevineSecurityLevel: String? by lazy {
        runCatching {
            val drm = android.media.MediaDrm(C.WIDEVINE_UUID)
            val level = drm.getPropertyString("securityLevel")
            if (android.os.Build.VERSION.SDK_INT >= 28) drm.close() else @Suppress("DEPRECATION") drm.release()
            level
        }.getOrNull()
    }

    /**
     * Provider de [ExoMediaDrm] que opcionalmente fuerza Widevine L3.
     * L3 = descifrado por software: no requiere decodificador/superficie segura,
     * lo que elimina la "pantalla negra con audio" en dispositivos L1 problemáticos.
     */
    fun mediaDrmProvider(forceL3: Boolean): ExoMediaDrm.Provider = ExoMediaDrm.Provider { uuid ->
        try {
            val drm = FrameworkMediaDrm.newInstance(uuid)
            if (forceL3 && uuid == C.WIDEVINE_UUID) {
                runCatching { drm.setPropertyString("securityLevel", "L3") }
                    .onSuccess { Log.i(TAG, "Widevine forzado a L3") }
                    .onFailure { Log.w(TAG, "No se pudo forzar L3: ${it.message}") }
            }
            drm
        } catch (e: UnsupportedDrmException) {
            Log.e(TAG, "Esquema DRM no soportado por el dispositivo: $uuid", e)
            DummyExoMediaDrm()
        }
    }

    /**
     * Construye el [DrmSessionManager] para insertar en el MediaSource.
     *
     * @param licenseFactory DataSource para peticiones de licencia (con headers del canal).
     * @param forceL3 fuerza Widevine L3 (se usa también como fallback automático).
     */
    fun buildDrmSessionManager(
        channel: StreamChannel,
        licenseFactory: DataSource.Factory,
        forceL3: Boolean = channel.forceWidevineL3
    ): DrmSessionManager? = when (channel.drmScheme) {

        DrmScheme.NONE -> null

        DrmScheme.CLEARKEY -> {
            val localData = channel.clearKeyLicenseData
            if (!localData.isNullOrBlank()) {
                // ClearKeyParseException se propaga → error DRM_PARSE claro hacia Flutter.
                val keys = ClearKeyParser.parse(localData)
                Log.d(TAG, "ClearKey local: ${keys.size} clave(s)")
                ClearKeyManager.createDrmSessionManager(keys)
            } else {
                channel.licenseUrl?.let { url ->
                    Log.d(TAG, "ClearKey remoto: ${sanitize(url)}")
                    remoteManager(C.CLEARKEY_UUID, url, channel, licenseFactory, false, secure = false)
                }
            }
        }

        DrmScheme.WIDEVINE -> channel.licenseUrl?.let { url ->
            Log.d(TAG, "Widevine: ${sanitize(url)} (nivel dispositivo=$widevineSecurityLevel, forceL3=$forceL3)")
            remoteManager(C.WIDEVINE_UUID, url, channel, licenseFactory, forceL3, secure = true)
        }

        DrmScheme.PLAYREADY -> channel.licenseUrl?.let { url ->
            Log.d(TAG, "PlayReady: ${sanitize(url)}")
            remoteManager(C.PLAYREADY_UUID, url, channel, licenseFactory, false, secure = true)
        }
    }

    private fun remoteManager(
        uuid: UUID,
        licenseUrl: String,
        channel: StreamChannel,
        licenseFactory: DataSource.Factory,
        forceL3: Boolean,
        secure: Boolean
    ): DrmSessionManager {
        // forceDefaultLicenseUrl = true → ignora LA_URL embebidas en el manifiesto.
        val callback = HttpMediaDrmCallback(licenseUrl, /* forceDefaultLicenseUrl = */ true, licenseFactory)
        channel.licenseHeaders.forEach { (k, v) -> callback.setKeyRequestProperty(k, v) }

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(uuid, mediaDrmProvider(forceL3))
            .setMultiSession(false)
            .setPlayClearSamplesWithoutKeys(true)
            .apply {
                // Mantener el decodificador seguro durante tramos claros evita
                // reinicializaciones del codec (pantallazos negros) en clear-lead.
                if (secure) setUseDrmSessionsForClearContent(C.TRACK_TYPE_VIDEO, C.TRACK_TYPE_AUDIO)
            }
            .build(callback)
    }

    private fun sanitize(url: String): String = url.substringBefore('?').take(80)
}
