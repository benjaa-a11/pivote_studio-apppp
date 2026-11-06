package com.example.pivote_studio.drm

import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.drm.DefaultDrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.LocalMediaDrmCallback
import org.json.JSONArray
import org.json.JSONObject

/**
 * Gestor de DRM ClearKey local para Media3 / ExoPlayer.
 *
 * Construye la respuesta de licencia W3C (JSON) en memoria y la entrega a la CDM
 * ClearKey de Android mediante [LocalMediaDrmCallback] — sin peticiones HTTP.
 * Funciona con DASH (CENC/CBCS, PSSH ClearKey o Common PSSH + default_KID) y
 * HLS fMP4 con KEYFORMAT org.w3.clearkey.
 */
@OptIn(UnstableApi::class)
object ClearKeyManager {

    private const val TAG = "ClearKeyManager"

    /**
     * Construye un DrmSessionManager configurado con las claves ClearKey suministradas.
     * @param keys Lista de pares ClearKeyData parseados
     */
    fun createDrmSessionManager(keys: List<ClearKeyData>): DrmSessionManager {
        require(keys.isNotEmpty()) { "La lista de claves ClearKey no puede estar vacía" }

        // Logging sanitizado (nunca exponer claves completas en logcat)
        keys.forEach { Log.d(TAG, "ClearKey configurada → kid=${ClearKeyParser.sanitizeKey(it.kid)}") }

        val callback = LocalMediaDrmCallback(buildClearKeyJson(keys).toByteArray(Charsets.UTF_8))

        return DefaultDrmSessionManager.Builder()
            .setUuidAndExoMediaDrmProvider(C.CLEARKEY_UUID, PivoteDrmManager.mediaDrmProvider(false))
            // Una sola sesión con todas las claves: evita renegociar por pista/periodo.
            .setMultiSession(false)
            // Reproducir los segmentos claros (clear lead / publicidad) sin esperar claves.
            .setPlayClearSamplesWithoutKeys(true)
            .build(callback)
    }

    /**
     * Construye la estructura JSON compatible con el estándar W3C ClearKey / Media3.
     */
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
