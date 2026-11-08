package com.example.pivote_studio.drm

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
import com.example.pivote_studio.data.DrmEncryptionScheme
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.player.NativePlayerConfig
import java.util.UUID

/**
 * Gestor de DRM unificado para Media3 / ExoPlayer.
 *
 * Soporta:
 *   • ClearKey local (kid:k / JSON W3C) → [LocalMediaDrmCallback] con MultiSession=true
 *   • ClearKey remoto (servidor de licencias W3C) → [HttpMediaDrmCallback] con MultiSession=true
 *   • Widevine Modular (CENC y CBCS) con headers propios, MultiSession=true y fallback L1 → L3
 *   • PlayReady con MultiSession=true
 */
@OptIn(UnstableApi::class)
object PivoteDrmManager {

    private const val SUBTAG = "DrmManager"

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
     * Provider de [ExoMediaDrm] que opcionalmente fuerza Widevine L3 y configura
     * compatibilidad para esquemas CENC / CBCS.
     */
    fun mediaDrmProvider(
        forceL3: Boolean,
        encryptionScheme: DrmEncryptionScheme = DrmEncryptionScheme.AUTO
    ): ExoMediaDrm.Provider = ExoMediaDrm.Provider { uuid ->
        try {
            val drm = FrameworkMediaDrm.newInstance(uuid)
            if (uuid == C.WIDEVINE_UUID) {
                if (forceL3) {
                    runCatching { drm.setPropertyString("securityLevel", "L3") }
                        .onSuccess {
                            NativePlayerConfig.logI(
                                SUBTAG,
                                "Widevine fijado en L3 (encryption=$encryptionScheme)"
                            )
                        }
                        .onFailure {
                            NativePlayerConfig.logW(SUBTAG, "No se pudo fijar Widevine L3: ${it.message}")
                        }
                }
                // Evita bloqueos de sesión cuando un stream alterna periodos en vivo
                runCatching { drm.setPropertyString("sessionSharing", "enable") }
            }
            drm
        } catch (e: UnsupportedDrmException) {
            NativePlayerConfig.logE(SUBTAG, "Esquema DRM no soportado por el dispositivo: $uuid", e)
            DummyExoMediaDrm()
        }
    }

    /**
     * Construye el [DrmSessionManager] único para inyectar en el MediaSource.
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
                val keys = ClearKeyParser.parse(localData)
                NativePlayerConfig.logD(
                    SUBTAG,
                    "ClearKey local configurado (${keys.size} clave(s), scheme=${channel.encryptionScheme})"
                )
                ClearKeyManager.createDrmSessionManager(keys)
            } else {
                channel.licenseUrl?.let { url ->
                    NativePlayerConfig.logD(SUBTAG, "ClearKey remoto: ${sanitize(url)}")
                    remoteManager(C.CLEARKEY_UUID, url, channel, licenseFactory, false)
                }
            }
        }

        DrmScheme.WIDEVINE -> channel.licenseUrl?.let { url ->
            NativePlayerConfig.logD(
                SUBTAG,
                "Widevine: ${sanitize(url)} (hwLevel=$widevineSecurityLevel, forceL3=$forceL3, enc=${channel.encryptionScheme})"
            )
            remoteManager(C.WIDEVINE_UUID, url, channel, licenseFactory, forceL3)
        }

        DrmScheme.PLAYREADY -> channel.licenseUrl?.let { url ->
            NativePlayerConfig.logD(SUBTAG, "PlayReady: ${sanitize(url)}")
            remoteManager(C.PLAYREADY_UUID, url, channel, licenseFactory, false)
        }
    }

    private fun remoteManager(
        uuid: UUID,
        licenseUrl: String,
        channel: StreamChannel,
        licenseFactory: DataSource.Factory,
        forceL3: Boolean
    ): DrmSessionManager {
        val callback = HttpMediaDrmCallback(licenseUrl, /* forceDefaultLicenseUrl = */ false, licenseFactory)
        channel.licenseHeaders.forEach { (k, v) -> callback.setKeyRequestProperty(k, v) }

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(uuid, mediaDrmProvider(forceL3, channel.encryptionScheme))
            // CRÍTICO: MultiSession=true para desencriptar audio y video en AdaptationSets separados (CENC y CBCS)
            .setMultiSession(channel.drmConfig.multiSession)
            .setPlayClearSamplesWithoutKeys(true)
            .build(callback)
    }

    private fun sanitize(url: String): String = url.substringBefore('?').take(80)
}
