package com.example.pivote_studio

import android.util.Base64
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.drm.ExoMediaDrm
import androidx.media3.exoplayer.drm.MediaDrmCallback
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Professional MediaDrmCallback for ClearKey DRM.
 * Supports static key injection with both hex and UUID byte-swap formats.
 * 
 * This implementation provides a robust solution for DASH MPD streams with ClearKey DRM,
 * eliminating the unreliable data URI approach.
 */
@OptIn(UnstableApi::class)
class ClearKeyDrmCallback(
    private val keyId: String,
    private val keyValue: String,
    private val useUuidSwap: Boolean = false
) : MediaDrmCallback {

    companion object {
        private const val TAG = "ClearKeyDrmCallback"
    }

    /**
     * Executes the key request.
     * For ClearKey, we generate a static JSON response with the provided keys.
     */
    override fun executeKeyRequest(
        uuid: UUID,
        request: ExoMediaDrm.KeyRequest
    ): ByteArray {
        Log.d(TAG, "executeKeyRequest called")
        Log.d(TAG, "UUID: $uuid")
        Log.d(TAG, "Request type: ${request.requestType}")
        
        // Verify it's a ClearKey request
        if (uuid != C.CLEARKEY_UUID) {
            Log.e(TAG, "Unexpected DRM UUID: $uuid (expected ClearKey)")
            throw IllegalArgumentException("Only ClearKey DRM is supported")
        }

        return try {
            val licenseResponse = generateClearKeyLicense(keyId, keyValue, useUuidSwap)
            Log.d(TAG, "Generated ClearKey license successfully")
            licenseResponse.toByteArray(Charsets.UTF_8)
        } catch (e: Exception) {
            Log.e(TAG, "Error generating ClearKey license", e)
            throw e
        }
    }

    /**
     * Executes the provisioning request.
     * ClearKey doesn't require provisioning, so this returns an empty response.
     */
    override fun executeProvisionRequest(
        uuid: UUID,
        request: ExoMediaDrm.ProvisionRequest
    ): ByteArray {
        Log.d(TAG, "executeProvisionRequest called (not needed for ClearKey)")
        return ByteArray(0)
    }

    /**
     * Generates a ClearKey license JSON response.
     * 
     * Format:
     * {
     *   "keys": [
     *     {
     *       "kty": "oct",
     *       "k": "<base64_key_value>",
     *       "kid": "<base64_key_id>"
     *     }
     *   ],
     *   "type": "temporary"
     * }
     */
    private fun generateClearKeyLicense(
        kid: String,
        key: String,
        useUuidSwap: Boolean
    ): String {
        // Convert key ID
        val kidBase64 = if (useUuidSwap) {
            uuidToBase64(kid)
        } else {
            hexToBase64(kid)
        }
        
        // Convert key value (always hex to base64)
        val keyBase64 = hexToBase64(key)
        
        Log.d(TAG, "Key ID (base64): ${kidBase64.take(16)}...")
        Log.d(TAG, "Key Value (base64): ${keyBase64.take(16)}...")
        
        // Build JSON
        val licenseJson = JSONObject().apply {
            put("keys", JSONArray().apply {
                put(JSONObject().apply {
                    put("kty", "oct")
                    put("k", keyBase64)
                    put("kid", kidBase64)
                })
            })
            put("type", "temporary")
        }
        
        return licenseJson.toString()
    }

    /**
     * Converts hex string to URL-safe base64 without padding.
     */
    private fun hexToBase64(hex: String): String {
        val cleanHex = hex.replace(Regex("[^0-9A-Fa-f]"), "")
        
        if (cleanHex.length % 2 != 0) {
            throw IllegalArgumentException("Invalid hex string length: ${cleanHex.length}")
        }
        
        val bytes = ByteArray(cleanHex.length / 2) { i ->
            cleanHex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
        }
        
        return Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
        )
    }

    /**
     * Converts UUID with Microsoft-style byte swapping to base64.
     * This is needed for some DRM providers that use GUID format.
     */
    private fun uuidToBase64(hex: String): String {
        val cleanHex = hex.replace("-", "").replace(Regex("[^0-9A-Fa-f]"), "")
        
        if (cleanHex.length != 32) {
            Log.w(TAG, "UUID length is not 32, falling back to hex conversion")
            return hexToBase64(hex)
        }
        
        try {
            val original = ByteArray(16) { i ->
                cleanHex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
            }
            
            val swapped = ByteArray(16)
            
            // Swap first 4 bytes (DWORD)
            swapped[0] = original[3]
            swapped[1] = original[2]
            swapped[2] = original[1]
            swapped[3] = original[0]
            
            // Swap next 2 bytes (WORD)
            swapped[4] = original[5]
            swapped[5] = original[4]
            
            // Swap next 2 bytes (WORD)
            swapped[6] = original[7]
            swapped[7] = original[6]
            
            // Remaining 8 bytes stay the same
            System.arraycopy(original, 8, swapped, 8, 8)
            
            return Base64.encodeToString(
                swapped,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error in UUID byte swap, falling back to hex", e)
            return hexToBase64(hex)
        }
    }
}
