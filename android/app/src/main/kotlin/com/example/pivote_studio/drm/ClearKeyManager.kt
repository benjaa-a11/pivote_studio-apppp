package com.example.pivote_studio.drm

import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
import com.example.pivote_studio.player.NativePlayerConfig
import org.json.JSONArray
import org.json.JSONObject

/**
 * Gestor de DRM ClearKey local para Media3 / ExoPlayer.
 *
 * Construye la respuesta de licencia W3C (JSON) en memoria y la entrega a la CDM
 * ClearKey de Android mediante [LocalMediaDrmCallback] — sin peticiones HTTP.
 *
 * IMPORTANTE:
 *   • setMultiSession(true) es OBLIGATORIO para canales DASH / MPD con KIDs separados
 *     para video y audio (CENC y CBCS). Si está en false, sólo la primera pista (usualmente
 *     audio) abre sesión y el video queda en negro.
 */
@OptIn(UnstableApi::class)
object ClearKeyManager {

    private const val SUBTAG = "ClearKey"

    fun createDrmSessionManager(keys: List<ClearKeyData>): DrmSessionManager {
        require(keys.isNotEmpty()) { "La lista de claves ClearKey no puede estar vacía" }

        keys.forEach {
            NativePlayerConfig.logD(SUBTAG, "ClearKey configurada → kid=${ClearKeyParser.sanitizeKey(it.kid)}")
        }

        val callback = LocalMediaDrmCallback(buildClearKeyJson(keys).toByteArray(Charsets.UTF_8))

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(
                C.CLEARKEY_UUID,
                FrameworkMediaDrm.DEFAULT_PROVIDER
            )
            .setMultiSession(true)
            .setPlayClearSamplesWithoutKeys(true)
            .build(callback)
    }

    fun buildClearKeyJson(keys: List<ClearKeyData>): String {
        val keysArray = JSONArray()
        for (item in keys.distinctBy { it.kid }) {
            keysArray.put(
                JSONObject()
                    .put("kty", "oct")
                    .put("kid", item.kid)
                    .put("k", item.key)
            )
        }
        return JSONObject()
            .put("keys", keysArray)
            .put("type", "temporary")
            .toString()
    }
}
