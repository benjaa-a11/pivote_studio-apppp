import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/video/data/models/channel.dart';

// ════════════════════════════════════════════════════════════════════════════
// DrmKeyResolver — Smart ClearKey extractor for external DRM URLs
// ════════════════════════════════════════════════════════════════════════════
//
// Resolves ClearKey DRM license URLs like Supabase Edge Functions that return:
//   { "keys": [{"kty":"oct","kid":"base64url","k":"base64url"}], "type":"temporary" }
//
// Also handles:
//   • kid:VALUE,k:VALUE inline format
//   • {"kid":"...","k":"..."} single-key JSON
//   • Supabase / Cloudflare / custom edge function responses
//   • Caches resolved keys to avoid redundant network requests
// ════════════════════════════════════════════════════════════════════════════

class DrmKeyResolver {
  DrmKeyResolver._();

  // ── LRU cache: licenseUri → resolved keys ────────────────────────────────
  static final Map<String, Map<String, String>> _cache = {};
  static const int _cacheMaxSize = 200;

  // ── HTTP client with reasonable timeout ──────────────────────────────────
  static final http.Client _client = http.Client();
  static const Duration _fetchTimeout = Duration(seconds: 8);

  /// Attempts to resolve DRM keys from the given license URI.
  ///
  /// Returns a [Map<kidHex, keyHex>] suitable for ClearKey DRM, or null
  /// if resolution fails. Results are cached by license URI.
  static Future<Map<String, String>?> resolve(
    String licenseUri, {
    Map<String, String>? requestHeaders,
  }) async {
    if (licenseUri.isEmpty) return null;

    // Check cache first
    if (_cache.containsKey(licenseUri)) {
      debugPrint('🔑 DrmKeyResolver [CACHE HIT] $licenseUri');
      return _cache[licenseUri];
    }

    // Try inline format first (no network needed)
    final inline = StreamSource.parseDrmLicenseUri(licenseUri);
    if (inline.isNotEmpty) {
      debugPrint('🔑 DrmKeyResolver [INLINE] ${inline.length} key(s)');
      _putCache(licenseUri, inline);
      return inline;
    }

    // Looks like a URL — fetch it
    final parsed = Uri.tryParse(licenseUri);
    if (parsed == null || !parsed.hasScheme) return null;

    try {
      debugPrint('🔑 DrmKeyResolver [FETCH] $licenseUri');

      final headers = <String, String>{
        'Accept': 'application/json, */*',
        'Content-Type': 'application/json',
        ...?requestHeaders,
      };

      // Try GET first (most Supabase edge functions respond to GET)
      http.Response response;
      try {
        response = await _client
            .get(parsed, headers: headers)
            .timeout(_fetchTimeout);
      } catch (_) {
        // Fallback POST with empty body (some license servers require POST)
        response = await _client
            .post(parsed, headers: headers, body: '{}')
            .timeout(_fetchTimeout);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = utf8.decode(response.bodyBytes);
        debugPrint('🔑 DrmKeyResolver [RESPONSE] ${body.substring(0, body.length.clamp(0, 200))}');

        final keys = _parseResponseBody(body);
        if (keys != null && keys.isNotEmpty) {
          debugPrint('🔑 DrmKeyResolver [RESOLVED] ${keys.length} key(s): $keys');
          _putCache(licenseUri, keys);
          return keys;
        }
      } else {
        debugPrint('⚠️ DrmKeyResolver HTTP ${response.statusCode} for $licenseUri');
      }
    } on TimeoutException {
      debugPrint('⏱ DrmKeyResolver timeout: $licenseUri');
    } catch (e) {
      debugPrint('❌ DrmKeyResolver error: $e');
    }

    return null;
  }

  /// Parses a response body that may contain ClearKey JSON in any of:
  ///   • JWK Set: {"keys": [{"kty":"oct","kid":"...","k":"..."}], "type":"..."}
  ///   • Single: {"kid":"...","k":"..."}
  ///   • Wrapped: {"llaves": [...], "tipo": "temporal"} (Spanish variant)
  ///   • kid:VALUE,k:VALUE inline
  static Map<String, String>? _parseResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    // Try JSON formats
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(trimmed);

        // Standard JWK Set: {"keys": [...]}
        if (decoded is Map && decoded['keys'] is List) {
          return _extractFromKeyList(decoded['keys'] as List);
        }

        // Spanish variant: {"llaves": [...], "tipo": "temporal"}
        if (decoded is Map && decoded['llaves'] is List) {
          return _extractFromKeyList(decoded['llaves'] as List);
        }

        // Single key object: {"kid":"...","k":"..."}
        if (decoded is Map && decoded['kid'] != null && decoded['k'] != null) {
          final kidHex = StreamSource.normalizeKeyToHex(decoded['kid'].toString());
          final kHex = StreamSource.normalizeKeyToHex(decoded['k'].toString());
          if (kidHex.isNotEmpty && kHex.isNotEmpty) {
            return {kidHex: kHex};
          }
        }

        // Array of key objects
        if (decoded is List) {
          return _extractFromKeyList(decoded);
        }
      } catch (e) {
        debugPrint('⚠️ DrmKeyResolver JSON parse error: $e');
      }
    }

    // Try inline format
    final inline = StreamSource.parseDrmLicenseUri(trimmed);
    if (inline.isNotEmpty) return inline;

    return null;
  }

  static Map<String, String>? _extractFromKeyList(List keys) {
    final result = <String, String>{};
    for (final k in keys) {
      if (k is Map) {
        final kidRaw = k['kid']?.toString() ?? k['niño']?.toString();
        final kRaw = k['k']?.toString();
        if (kidRaw != null && kRaw != null) {
          final kidHex = StreamSource.normalizeKeyToHex(kidRaw);
          final kHex = StreamSource.normalizeKeyToHex(kRaw);
          if (kidHex.isNotEmpty && kHex.isNotEmpty) {
            result[kidHex] = kHex;
          }
        }
      }
    }
    return result.isNotEmpty ? result : null;
  }

  static void _putCache(String key, Map<String, String> value) {
    if (_cache.length >= _cacheMaxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  /// Clears the key cache (useful for testing or force-refresh)
  static void clearCache() => _cache.clear();
}
