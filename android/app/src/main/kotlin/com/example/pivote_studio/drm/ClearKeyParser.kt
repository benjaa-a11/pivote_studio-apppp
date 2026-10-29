package com.example.pivote_studio.drm

import android.util.Base64
import org.json.JSONObject
import java.util.regex.Pattern

/**
 * Representa un par estructurado Key ID y Key para ClearKey DRM.
 * Ambos valores garantizan estar en formato Base64URL sin padding.
 */
data class ClearKeyData(
    val kid: String,
    val key: String
)

/**
 * Excepción lanzada cuando la información de DRM ClearKey no puede ser parseada o es inválida.
 */
class ClearKeyParseException(message: String, cause: Throwable? = null) : IllegalArgumentException(message, cause)

/**
 * Parser independiente y seguro para cadenas de licencias ClearKey.
 * Soporta formatos:
 * - "kid:XXXXX,k:YYYYY"
 * - "kid:AAA,k:BBB,kid:CCC,k:DDD"
 * - Variaciones con espacios ("kid: XXXXX , k: YYYYY")
 * - Variaciones de mayúsculas/minúsculas ("KID:..., K:...")
 * - Cadenas JSON con objeto "keys"
 * - Conversión automática de claves Hexadecimales (32 caracteres) a Base64URL
 */
object ClearKeyParser {

    private val PAIR_REGEX = Pattern.compile(
        "(?i)kid\\s*:\\s*([^,;\\s]+)[,;\\s]+k(?:ey)?\\s*:\\s*([^,;\\s]+)"
    )

    private val INVERSE_PAIR_REGEX = Pattern.compile(
        "(?i)k(?:ey)?\\s*:\\s*([^,;\\s]+)[,;\\s]+kid\\s*:\\s*([^,;\\s]+)"
    )

    /**
     * Parsea la cadena drm_license_uri y retorna una lista no vacía de pares ClearKeyData.
     * @throws ClearKeyParseException si la cadena está vacía o el formato es inválido.
     */
    fun parse(drmLicenseUri: String?): List<ClearKeyData> {
        if (drmLicenseUri.isNullOrBlank()) {
            throw ClearKeyParseException("drm_license_uri no puede ser nulo o vacío")
        }

        val trimmed = drmLicenseUri.trim()
        val results = mutableListOf<ClearKeyData>()

        // 1. Verificar si viene como JSON
        if ((trimmed.startsWith("{") && trimmed.endsWith("}")) || (trimmed.startsWith("[") && trimmed.endsWith("]"))) {
            try {
                if (trimmed.startsWith("[")) {
                    val arr = org.json.JSONArray(trimmed)
                    for (i in 0 until arr.length()) {
                        val keyObj = arr.getJSONObject(i)
                        val kid = keyObj.optString("kid", "").trim()
                        val k = keyObj.optString("k", "").trim()
                        if (kid.isNotEmpty() && k.isNotEmpty()) {
                            results.add(
                                ClearKeyData(
                                    kid = toBase64Url(kid),
                                    key = toBase64Url(k)
                                )
                            )
                        }
                    }
                } else {
                    val json = JSONObject(trimmed)
                    val keysArray = when {
                        json.has("keys") -> json.getJSONArray("keys")
                        json.has("llaves") -> json.getJSONArray("llaves")
                        else -> null
                    }

                    if (keysArray != null) {
                        for (i in 0 until keysArray.length()) {
                            val keyObj = keysArray.getJSONObject(i)
                            val kid = keyObj.optString("kid", "").trim()
                            val k = keyObj.optString("k", "").trim()
                            if (kid.isNotEmpty() && k.isNotEmpty()) {
                                results.add(
                                    ClearKeyData(
                                        kid = toBase64Url(kid),
                                        key = toBase64Url(k)
                                    )
                                )
                            }
                        }
                    } else if (json.has("kid") && (json.has("k") || json.has("key"))) {
                        val kid = json.optString("kid", "").trim()
                        val k = (if (json.has("k")) json.optString("k", "") else json.optString("key", "")).trim()
                        if (kid.isNotEmpty() && k.isNotEmpty()) {
                            results.add(
                                ClearKeyData(
                                    kid = toBase64Url(kid),
                                    key = toBase64Url(k)
                                )
                            )
                        }
                    }
                }
                if (results.isNotEmpty()) {
                    return results
                }
            } catch (e: Exception) {
                // Fallback to regex parsing if JSON fails
            }
        }

        // 2. Parseo mediante expresiones regulares (kid:XXX, k:YYY)
        val matcher = PAIR_REGEX.matcher(trimmed)
        while (matcher.find()) {
            val rawKid = matcher.group(1)?.trim() ?: ""
            val rawKey = matcher.group(2)?.trim() ?: ""

            if (rawKid.isNotEmpty() && rawKey.isNotEmpty()) {
                results.add(
                    ClearKeyData(
                        kid = toBase64Url(rawKid),
                        key = toBase64Url(rawKey)
                    )
                )
            }
        }

        // 3. Si no encontró pares, probar orden inverso (k:YYY, kid:XXX)
        if (results.isEmpty()) {
            val inverseMatcher = INVERSE_PAIR_REGEX.matcher(trimmed)
            while (inverseMatcher.find()) {
                val rawKey = inverseMatcher.group(1)?.trim() ?: ""
                val rawKid = inverseMatcher.group(2)?.trim() ?: ""

                if (rawKid.isNotEmpty() && rawKey.isNotEmpty()) {
                    results.add(
                        ClearKeyData(
                            kid = toBase64Url(rawKid),
                            key = toBase64Url(rawKey)
                        )
                    )
                }
            }
        }

        if (results.isEmpty()) {
            throw ClearKeyParseException(
                "Formato ClearKey inválido. No se pudieron extraer pares kid/k de: ${sanitizeLogString(trimmed)}"
            )
        }

        return results
    }

    /**
     * Convierte una clave o KID a formato Base64URL (RFC 7515 / RFC 4648 sin padding).
     * Soporta valores en Hexadecimal puro (32 caracteres) y Base64 tradicional.
     */
    fun toBase64Url(keyOrKid: String): String {
        val clean = keyOrKid.trim()
        val cleanHex = clean.replace("-", "").replace(" ", "")

        // Caso Hexadecimal de 32 caracteres (16 bytes)
        if (cleanHex.length == 32 && cleanHex.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) {
            val bytes = hexToBytes(cleanHex)
            return Base64.encodeToString(
                bytes,
                Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
            ).trim()
        }

        // Ya es Base64 o Base64URL: normalizar caracteres y remover padding '='
        return clean
            .replace('+', '-')
            .replace('/', '_')
            .replace("=", "")
            .trim()
    }

    private fun hexToBytes(hex: String): ByteArray {
        val len = hex.length
        val data = ByteArray(len / 2)
        var i = 0
        while (i < len) {
            data[i / 2] = ((Character.digit(hex[i], 16) shl 4) +
                    Character.digit(hex[i + 1], 16)).toByte()
            i += 2
        }
        return data
    }

    /**
     * Sanitiza una clave para impresión segura en logs (evita fugar información confidencial).
     * Ejemplo: "Gwq2...3w"
     */
    fun sanitizeKey(key: String): String {
        val trimmed = key.trim()
        if (trimmed.length <= 6) return "***"
        return "${trimmed.take(4)}...${trimmed.takeLast(2)}"
    }

    /**
     * Sanitiza una cadena general de licencia para logs sin exponer claves.
     */
    fun sanitizeLogString(raw: String): String {
        return raw.replace(Regex("(?i)(kid|k|key)\\s*:\\s*([^,;\\s]+)")) { matchResult ->
            val param = matchResult.groupValues[1]
            val value = matchResult.groupValues[2]
            "$param:${sanitizeKey(value)}"
        }
    }
}
