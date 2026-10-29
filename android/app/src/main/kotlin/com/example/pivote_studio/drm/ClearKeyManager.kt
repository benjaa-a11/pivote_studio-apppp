package com.example.pivote_studio.drm

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.FrameworkMediaDrm
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
import org.json.JSONArray
import org.json.JSONObject

/**
 * Gestor de DRM ClearKey para Media3 / ExoPlayer.
 * Construye dinámicamente la respuesta JSON temporal y el DefaultDrmSessionManager
 * utilizando C.CLEARKEY_UUID y LocalMediaDrmCallback, sin peticiones remotas HTTP.
 */
@OptIn(UnstableApi::class)
object ClearKeyManager {

    private const val TAG = "ClearKeyManager"

    /**
     * Construye un DrmSessionManager configurado con las claves ClearKey suministradas.
     * @param keys Lista de pares ClearKeyData parseados
     */
    fun createDrmSessionManager(keys: List<ClearKeyData>): DrmSessionManager {
        if (keys.isEmpty()) {
            throw IllegalArgumentException("La lista de claves ClearKey no puede estar vacía")
        }

        val clearKeyJson = buildClearKeyJson(keys)

        // Logging sanitizado (nunca exponer claves completas en logcat)
        for (item in keys) {
            Log.d(TAG, "DRM: ClearKey configured -> kid=${ClearKeyParser.sanitizeKey(item.kid)}")
        }

        val drmCallback = LocalMediaDrmCallback(clearKeyJson.toByteArray(Charsets.UTF_8))

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(
                C.CLEARKEY_UUID,
                FrameworkMediaDrm.DEFAULT_PROVIDER
            )
            .setMultiSession(true)
            .setPlayClearSamplesWithoutKeys(true)
            .build(drmCallback)
    }

    /**
     * Construye la estructura JSON temporal compatible con el estándar W3C ClearKey / Media3.
     */
    fun buildClearKeyJson(keys: List<ClearKeyData>): String {
        val root = JSONObject()
        val keysArray = JSONArray()

        for (item in keys) {
            val keyObj = JSONObject()
            keyObj.put("kty", "oct")
            keyObj.put("kid", item.kid)
            keyObj.put("k", item.key)
            keysArray.put(keyObj)
        }

        root.put("keys", keysArray)
        root.put("type", "temporary")

        return root.toString()
    }
}
