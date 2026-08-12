import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

// ════════════════════════════════════════════════════════════════════════════
// StreamUrlResolver v2.0 — Universal PHP/Web → M3U8 resolver
// ════════════════════════════════════════════════════════════════════════════
//
// Strategies (in priority order):
//   [A] var playbackURL = "https://...m3u8..."    — direct assignment
//   [B] GB-array + atob() + numeric offset        — JS obfuscation (Clappr pages)
//   [C] JWPlayer / Clappr / VideoJS configs        — file:/hls:/src: patterns
//   [D] <video src> / <source src>                — HTML5 semantic tags
//   [E] Generic .m3u8 URL in page body            — fallback regex
//   [F] HTTP redirect chain → .m3u8 final URL     — Location header
//
// Cache: LRU 12 entries, TTL 5 minutes (avoids re-scraping same PHP page)
//

// ── Configuration ─────────────────────────────────────────────────────────

class _ResolverConfig {
  _ResolverConfig._();

  static const Duration pageTimeout = Duration(seconds: 12);
  static const Duration cacheTtl = Duration(minutes: 5);
  static const int cacheMaxSize = 12;
  static const int maxRedirects = 8;

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/125.0.0.0 Safari/537.36';

  // Strings that immediately confirm it's already a playable direct M3U8
  static const List<String> m3u8FastPaths = [
    '.m3u8',
    '.m3u8?',
    'akamaized.net',
    'cloudfront.net',
    'fastly.net',
    'llnw.net',
  ];

  // Content-Type values that mean the response IS the stream
  static const List<String> streamMimeTypes = [
    'mpegurl',
    'x-mpegurl',
    'vnd.apple.mpegurl',
    'octet-stream', // Some servers send m3u8 as binary
  ];
}

// ── Cache Entry ───────────────────────────────────────────────────────────

class _CacheEntry {
  final String resolvedUrl;
  final DateTime expiresAt;

  _CacheEntry(this.resolvedUrl)
      : expiresAt = DateTime.now().add(_ResolverConfig.cacheTtl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ── Result ────────────────────────────────────────────────────────────────

class ResolveResult {
  /// The resolved playback URL (M3U8 or original if already direct)
  final String url;

  /// The original PHP/web page URL (to use as Referer when loading the stream)
  final String? referer;

  /// Which strategy found the URL (for debug logging)
  final String strategy;

  const ResolveResult({
    required this.url,
    this.referer,
    required this.strategy,
  });

  bool get wasResolved => strategy != 'passthrough' && strategy != 'direct';
}

// ════════════════════════════════════════════════════════════════════════════
// StreamUrlResolver
// ════════════════════════════════════════════════════════════════════════════

class StreamUrlResolver {
  StreamUrlResolver._();

  // ── LRU Cache ─────────────────────────────────────────────────────────
  static final _cache = <String, _CacheEntry>{};

  static void _putCache(String url, String resolved) {
    // Evict expired entries first
    _cache.removeWhere((_, v) => v.isExpired);

    // LRU eviction if still full
    if (_cache.length >= _ResolverConfig.cacheMaxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[url] = _CacheEntry(resolved);
    debugPrint('🗄️ Resolver cached: ${resolved.substring(0, min(80, resolved.length))}');
  }

  static String? _getCache(String url) {
    final entry = _cache[url];
    if (entry == null) return null;
    if (entry.isExpired) {
      _cache.remove(url);
      return null;
    }
    return entry.resolvedUrl;
  }

  // ── Public API ────────────────────────────────────────────────────────

  /// Resolves [url] to a playable M3U8 stream URL.
  ///
  /// Returns a [ResolveResult] with the final URL and the original page URL
  /// as [referer] (useful when setting HTTP headers for the player).
  ///
  /// If the URL is already a direct M3U8 or fast-path CDN URL, it is
  /// returned immediately without any HTTP request.
  static Future<ResolveResult> resolve(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return ResolveResult(url: trimmed, strategy: 'empty');
    }

    final uLower = trimmed.toLowerCase();

    // ── 1. Already a direct M3U8 / CDN URL → skip resolution ──────────
    if (_isDirectStream(uLower)) {
      debugPrint('⚡ Resolver fast-path: $trimmed');
      return ResolveResult(url: trimmed, strategy: 'direct');
    }

    // ── 2. WebView / iframe / embed URLs → skip (handled by PivoProPlayer)
    if (_isWebViewUrl(uLower)) {
      debugPrint('🌐 Resolver skip (WebView): $trimmed');
      return ResolveResult(url: trimmed, strategy: 'passthrough');
    }

    // ── 3. MPD / DRM → skip (handled by ShakaPlayer) ──────────────────
    if (uLower.contains('.mpd')) {
      debugPrint('🔒 Resolver skip (MPD): $trimmed');
      return ResolveResult(url: trimmed, strategy: 'passthrough');
    }

    // ── 4. Cache hit ──────────────────────────────────────────────────
    final cached = _getCache(trimmed);
    if (cached != null) {
      debugPrint('💾 Resolver cache hit: ${cached.substring(0, min(80, cached.length))}');
      return ResolveResult(url: cached, referer: trimmed, strategy: 'cache');
    }

    // ── 5. Resolve via HTTP ───────────────────────────────────────────
    try {
      final resolved = await _resolveViaHttp(trimmed);
      if (resolved != null && resolved.isNotEmpty && resolved != trimmed) {
        _putCache(trimmed, resolved);
        return ResolveResult(url: resolved, referer: trimmed, strategy: 'http-resolved');
      }
    } catch (e) {
      debugPrint('❌ Resolver error: $e');
    }

    // ── 6. Fallback: return original URL as-is ────────────────────────
    debugPrint('⚠️ Resolver: no M3U8 found, using original URL');
    return ResolveResult(url: trimmed, strategy: 'fallback');
  }

  // ── HTTP Resolution Pipeline ──────────────────────────────────────────

  static Future<String?> _resolveViaHttp(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = _ResolverConfig.pageTimeout
        ..idleTimeout = _ResolverConfig.pageTimeout
        ..badCertificateCallback = (_, __, ___) => true;

      final uri = Uri.parse(url);
      final req = await client.getUrl(uri);

      req.followRedirects = true;
      req.maxRedirects = _ResolverConfig.maxRedirects;

      // Anti-bot headers — mimics a real Chrome browser on Windows
      req.headers
        ..set('User-Agent', _ResolverConfig.userAgent)
        ..set('Accept', 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8')
        ..set('Accept-Language', 'es-AR,es;q=0.9,en;q=0.8')
        ..set('Accept-Encoding', 'gzip, deflate, br')
        ..set('Connection', 'keep-alive')
        ..set('Upgrade-Insecure-Requests', '1')
        ..set('Referer', url)
        ..set('Origin', '${uri.scheme}://${uri.host}');

      final res = await req.close().timeout(_ResolverConfig.pageTimeout);

      // ── [F] Check redirect chain for .m3u8 ─────────────────────────
      if (res.redirects.isNotEmpty) {
        final finalUrl = res.redirects.last.location.toString();
        if (_containsM3u8(finalUrl)) {
          await res.drain<void>();
          debugPrint('🔁 Resolver [F] redirect → $finalUrl');
          return finalUrl;
        }
      }

      // ── Check Content-Type for stream MIME ─────────────────────────
      final ct = res.headers.contentType?.mimeType.toLowerCase() ?? '';
      if (_ResolverConfig.streamMimeTypes.any((m) => ct.contains(m))) {
        await res.drain<void>();
        debugPrint('📦 Resolver: Content-Type=$ct → using original URL');
        return url;
      }

      if (res.statusCode != 200) {
        await res.drain<void>();
        debugPrint('⚠️ Resolver HTTP ${res.statusCode}');
        return null;
      }

      // Read body (decompress gzip if needed)
      final body = await _readBody(res);
      if (body == null || body.isEmpty) return null;

      // If it's already an M3U8 playlist
      if (body.trimLeft().startsWith('#EXTM3U')) {
        debugPrint('📺 Resolver: body IS M3U8 → using original URL');
        return url;
      }

      // ── Run extraction strategies ───────────────────────────────────
      return _extractM3u8FromHtml(body, url, uri);
    } catch (e) {
      debugPrint('❌ Resolver HTTP error: $e');
      return null;
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
    }
  }

  // ── Body reader (handles gzip transparently) ─────────────────────────

  static Future<String?> _readBody(HttpClientResponse res) async {
    try {
      // HttpClient auto-decompresses gzip when 'gzip' encoding is set,
      // but some servers don't set it properly — try both ways
      final bytes = await res.fold<List<int>>(
        [],
        (prev, element) => prev..addAll(element),
      );
      // Try UTF-8 first, fallback to latin1
      try {
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        return latin1.decode(bytes);
      }
    } catch (e) {
      debugPrint('❌ Resolver: body read error: $e');
      return null;
    }
  }

  // ── Extraction Strategies ─────────────────────────────────────────────

  static String? _extractM3u8FromHtml(String body, String pageUrl, Uri baseUri) {
    // [A] var playbackURL = "https://...m3u8..."
    final a = strategyAPlaybackUrl(body);
    if (a != null) {
      debugPrint('✅ Resolver [A] playbackURL: ${a.substring(0, min(80, a.length))}');
      return a;
    }

    // [B] GB-array + atob() + numeric offset (Clappr pages)
    final b = strategyBGbArray(body);
    if (b != null) {
      debugPrint('✅ Resolver [B] GB-array: ${b.substring(0, min(80, b.length))}');
      return b;
    }

    // [C] JWPlayer / Clappr / VideoJS config patterns
    final c = strategyCPlayerConfigs(body);
    if (c != null) {
      debugPrint('✅ Resolver [C] player-config: ${c.substring(0, min(80, c.length))}');
      return c;
    }

    // [D] <video src> / <source src> HTML5 tags
    final d = strategyDHtmlTags(body, baseUri);
    if (d != null) {
      debugPrint('✅ Resolver [D] html-tag: ${d.substring(0, min(80, d.length))}');
      return d;
    }

    // [E] Generic .m3u8 URL anywhere in the page
    final e = strategyEGenericM3u8(body);
    if (e != null) {
      debugPrint('✅ Resolver [E] generic: ${e.substring(0, min(80, e.length))}');
      return e;
    }

    debugPrint('⚠️ Resolver: all strategies failed for $pageUrl');
    return null;
  }

  // ── [A] Direct playbackURL assignment ─────────────────────────────────
  // Matches:  var playbackURL = "https://..."
  //           playbackURL = 'https://...'
  //           let playbackURL="https://..."

  static String? strategyAPlaybackUrl(String body) {
    const patterns = [
      r'(?:var|let|const)?\s*playbackURL\s*=\s*["\x27](https?://[^"\x27\s<>]+)["\x27]',
      r'playbackURL\s*[+]=\s*["\x27](https?://[^"\x27\s<>]+)["\x27]',
      r'playback_url\s*[=:]\s*["\x27](https?://[^"\x27\s<>]+)["\x27]',
      r'stream_url\s*[=:]\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(body);
      if (match != null) {
        final found = match.group(1)!;
        if (_looksLikeStream(found)) return found;
      }
    }
    return null;
  }

  // ── [B] GB-array + atob + numeric offset (JS obfuscation) ─────────────
  //
  // Pattern used by some IPTV pages (Clappr embed):
  //   GB = [[134,"dWM2ODE3NDNheQ=="], [31,"RWs2ODE4MDhMaQ=="], ...];
  //   GB.sort((a,b) => a[0]-b[0]);
  //   var k = FuncA() + FuncB();   // e.g. 79613 + 602084 = 681697
  //   GB.forEach(e => {
  //     playbackURL += String.fromCharCode(parseInt(atob(e[1]).replace(/\D/g,'')) - k)
  //   });

  static String? strategyBGbArray(String body) {
    try {
      // 1. Find the GB array
      final gbMatch = RegExp(
        r'(?:var\s+)?GB\s*=\s*\[([\s\S]*?)\]\s*;',
        caseSensitive: false,
      ).firstMatch(body);
      if (gbMatch == null) return null;

      final gbRaw = gbMatch.group(1)!;

      // 2. Parse all [index, "base64"] pairs
      final pairRegex = RegExp(r'\[\s*(\d+)\s*,\s*["\x27]([A-Za-z0-9+/=]+)["\x27]\s*\]');
      final pairs = <int, String>{};
      for (final m in pairRegex.allMatches(gbRaw)) {
        final idx = int.tryParse(m.group(1)!);
        final b64 = m.group(2)!;
        if (idx != null) pairs[idx] = b64;
      }
      if (pairs.isEmpty) return null;

      // 3. Determine the offset k
      //    Strategy: look for numeric function returns and sum them
      //    e.g.  function KBAor(){return 79613;} function dGEJv(){return 602084;}
      int offset = _extractNumericOffset(body);

      // 4. Reconstruct URL: sort by index, decode base64, extract number, subtract offset
      final sortedKeys = pairs.keys.toList()..sort();
      final sb = StringBuffer();

      for (final idx in sortedKeys) {
        final b64 = pairs[idx]!;
        try {
          final decoded = utf8.decode(base64.decode(_padBase64(b64)));
          // Remove non-digits and parse as int
          final numStr = decoded.replaceAll(RegExp(r'\D'), '');
          if (numStr.isEmpty) continue;
          final num = int.tryParse(numStr);
          if (num == null) continue;
          final charCode = num - offset;
          if (charCode >= 32 && charCode <= 126) {
            sb.writeCharCode(charCode);
          }
        } catch (_) {
          continue;
        }
      }

      final candidate = sb.toString().trim();
      if (_looksLikeStream(candidate)) return candidate;

      // If we got a URL-like string but _looksLikeStream failed, try looser check
      if (candidate.startsWith('http') && candidate.length > 20) {
        return candidate;
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ Resolver [B] error: $e');
      return null;
    }
  }

  /// Extracts the numeric offset (k) used in the GB-array decoding.
  /// Sums all return values of short inline functions.
  static int _extractNumericOffset(String body) {
    // Try to find sum pattern: var k = FuncA() + FuncB()
    // where each function returns a hardcoded integer
    final funcReturnRegex = RegExp(r'function\s+\w+\s*\(\s*\)\s*\{\s*return\s+(\d+)\s*;\s*\}');
    final returns = funcReturnRegex.allMatches(body).map((m) => int.tryParse(m.group(1)!) ?? 0).toList();

    if (returns.length >= 2) {
      // Typically k = sum of all such functions
      final sum = returns.fold(0, (a, b) => a + b);
      debugPrint('🔑 Resolver [B] offset: $sum (from ${returns.length} functions: $returns)');
      return sum;
    }

    // Fallback: look for direct assignment  var k = 681697;
    final directMatch = RegExp(r'var\s+k\s*=\s*(\d+)').firstMatch(body);
    if (directMatch != null) {
      final k = int.tryParse(directMatch.group(1)!) ?? 0;
      debugPrint('🔑 Resolver [B] offset (direct): $k');
      return k;
    }

    debugPrint('⚠️ Resolver [B] could not determine offset — using 0');
    return 0;
  }

  // ── [C] JWPlayer / Clappr / VideoJS config ─────────────────────────────

  static String? strategyCPlayerConfigs(String body) {
    const patterns = [
      // JWPlayer: file: "..."
      r'''file\s*:\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      // Clappr: source: "..."
      r'''source\s*:\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      // VideoJS: src: "..."
      r'''src\s*:\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      // HLS source: hls: "..."
      r'''hls\s*:\s*["\x27](https?://[^"\x27\s<>]+)["\x27]''',
      // Generic stream key
      r'''["\x27]?(?:stream|live|hlsUrl|hls_url|streamUrl|stream_url|manifestUrl)["\x27]?\s*[=:]\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      // Flowplayer clip url
      r'''clip\s*:\s*\{[^}]*url\s*:\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
    ];

    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false, dotAll: true).firstMatch(body);
      if (m != null) {
        final url = m.group(1)!;
        if (_looksLikeStream(url)) return url;
      }
    }
    return null;
  }

  // ── [D] HTML5 <video> / <source> tags ──────────────────────────────────

  static String? strategyDHtmlTags(String body, Uri baseUri) {
    const patterns = [
      r'''<source[^>]+src\s*=\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      r'''<video[^>]+src\s*=\s*["\x27](https?://[^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
      r'''<source[^>]+src\s*=\s*["\x27]([^"\x27\s<>]+\.m3u8[^"\x27]*)["\x27]''',
    ];

    for (final pat in patterns) {
      final m = RegExp(pat, caseSensitive: false).firstMatch(body);
      if (m != null) {
        var found = m.group(1)!;
        // Resolve relative URLs
        if (!found.startsWith('http')) {
          try {
            found = baseUri.resolve(found).toString();
          } catch (_) {}
        }
        if (_looksLikeStream(found)) return found;
      }
    }
    return null;
  }

  // ── [E] Generic .m3u8 URL anywhere ─────────────────────────────────────

  static String? strategyEGenericM3u8(String body) {
    // Match any https://...m3u8... URL in the page
    final match = RegExp(
      "https?://[^\\s<>\"'\\\\]+\\.m3u8[^\\s<>\"'\\\\]*",
      caseSensitive: false,
    ).firstMatch(body);

    if (match != null) {
      final url = match.group(0)!;
      // Clean up common trailing characters: ) ] } ; , ' "
      final cleaned = url.replaceAll(RegExp("[)\\]};,'\"]+\$"), '');
      if (_looksLikeStream(cleaned)) return cleaned;
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static bool _isDirectStream(String uLower) {
    return _ResolverConfig.m3u8FastPaths.any((p) => uLower.contains(p));
  }

  static bool _isWebViewUrl(String uLower) {
    return uLower.contains('iframe') ||
        uLower.contains('embed') ||
        uLower.contains('pivo-pro') ||
        uLower.contains('pivopro') ||
        uLower.contains('vercel.app') ||
        uLower.contains('.html') && !uLower.endsWith('.php');
  }

  static bool _containsM3u8(String url) {
    final u = url.toLowerCase();
    return u.contains('.m3u8') || u.contains('m3u8?');
  }

  static bool _looksLikeStream(String url) {
    if (!url.startsWith('http')) return false;
    final u = url.toLowerCase();
    return u.contains('.m3u8') ||
        u.contains('m3u8?') ||
        u.contains('chunklist') ||
        u.contains('/live/') ||
        u.contains('/hls/') ||
        u.contains('/stream/') ||
        (u.contains('.ts') && u.length > 20);
  }

  /// Ensures base64 string has proper padding
  static String _padBase64(String b64) {
    final mod = b64.length % 4;
    if (mod == 0) return b64;
    return b64 + '=' * (4 - mod);
  }
}
