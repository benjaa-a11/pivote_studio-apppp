import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of resolving an embed / video-host page into a directly playable
/// stream. [primary] is the best guess; [candidates] is an ordered fallback
/// list the engine can walk through if the first one fails. [headers] carry
/// the Referer / Origin / User-Agent the CDN expects when the segments are
/// requested by the native player.
class EmbedResolution {
  final String primary;
  final List<String> candidates;
  final Map<String, String> headers;
  final String source; // debug label of how it was resolved

  const EmbedResolution({
    required this.primary,
    required this.candidates,
    required this.headers,
    this.source = 'unknown',
  });

  @override
  String toString() =>
      'EmbedResolution(source: $source, primary: $primary, candidates: ${candidates.length})';
}

/// Resolves streaming-host embed pages (StreamHG, StreamWish, Filemoon and
/// similar JWPlayer-based hosts) into a real `.m3u8` master playlist.
///
/// Supported input shapes, e.g.:
///   - `https://hgplaycdn.com/e/iqvwqvswf4fk`
///   - `https://callistanise.com/v/bg24l3g7ekgs`
///   - any page whose HTML embeds a jwplayer `sources:[{file:"...m3u8"}]`
///     block, a `links = { hls2: ..., hls3: ..., hls4: ... }` object, or a
///     Dean-Edwards packed (`eval(function(p,a,c,k,e,d){...})`) script that
///     contains the same.
///
/// Direct media URLs (`.m3u8`, `.mp4`, `.mkv`, …) are passed straight through.
class EmbedResolver {
  EmbedResolver._();
  static final EmbedResolver instance = EmbedResolver._();

  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';

  /// In-memory cache so re-opening the same movie in a session doesn't re-scrape.
  final Map<String, _CachedResolution> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 4);

  final http.Client _client = http.Client();

  /// Extensions that are already directly playable — skip all scraping.
  static final RegExp _directMedia = RegExp(
    r'\.(m3u8|mp4|mkv|webm|mov|m4v|ts|mpd|flv|avi)(\?|$)',
    caseSensitive: false,
  );

  bool isDirectMedia(String url) {
    final clean = url.split('#').first;
    return _directMedia.hasMatch(clean);
  }

  /// Heuristic: does this look like an embed/host page we should scrape?
  bool looksLikeEmbed(String url) {
    if (isDirectMedia(url)) return false;
    final u = url.toLowerCase();
    if (!u.startsWith('http')) return false;
    // Common embed path shapes: /e/<code>, /v/<code>, /embed-<code>, /d/<code>
    return RegExp(r'/(e|v|d|f|embed)[-/][a-z0-9]+', caseSensitive: false)
            .hasMatch(u) ||
        u.contains('embed');
  }

  /// Main entry point. Returns a resolution or throws on total failure.
  Future<EmbedResolution> resolve(
    String rawUrl, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final url = rawUrl.trim();

    // 1. Direct media → no scraping needed.
    if (isDirectMedia(url)) {
      return EmbedResolution(
        primary: url,
        candidates: [url],
        headers: _baseHeaders(url),
        source: 'direct',
      );
    }

    // 2. Cache.
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) {
      return cached.resolution;
    }

    // 3. Scrape the embed page.
    final resolution = await _scrape(url, timeout: timeout);
    _cache[url] = _CachedResolution(resolution, DateTime.now().add(_cacheTtl));
    return resolution;
  }

  Future<EmbedResolution> _scrape(
    String url, {
    required Duration timeout,
  }) async {
    final embedUrl = _normalizeToEmbed(url);
    final origin = _originOf(embedUrl);

    final headers = {
      'User-Agent': _userAgent,
      'Referer': '$origin/',
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9,es;q=0.8',
    };

    String html;
    try {
      final res = await _client
          .get(Uri.parse(embedUrl), headers: headers)
          .timeout(timeout);
      html = res.body;
      if (html.trim().isEmpty && embedUrl != url) {
        // Fallback to the original URL if the /e/ variant returned nothing.
        final res2 =
            await _client.get(Uri.parse(url), headers: headers).timeout(timeout);
        html = res2.body;
      }
    } catch (e) {
      debugPrint('❌ EmbedResolver fetch error for $embedUrl: $e');
      rethrow;
    }

    // Unpack any packed scripts and merge with the raw HTML so extraction
    // sees both plain and de-obfuscated code.
    final buffer = StringBuffer(html);
    for (final packed in _extractPackedBlocks(html)) {
      final unpacked = JsUnpacker.unpack(packed);
      if (unpacked != null && unpacked.isNotEmpty) {
        buffer.write('\n');
        buffer.write(unpacked);
      }
    }
    final combined = buffer.toString();

    final candidates = _extractStreamUrls(combined, base: embedUrl);
    if (candidates.isEmpty) {
      throw EmbedResolveException(
        'No se encontró ningún stream reproducible en $embedUrl',
      );
    }

    final playbackHeaders = {
      'User-Agent': _userAgent,
      'Referer': '$origin/',
      'Origin': origin,
    };

    return EmbedResolution(
      primary: candidates.first,
      candidates: candidates,
      headers: playbackHeaders,
      source: 'scraped(${candidates.length})',
    );
  }

  // ── Extraction ────────────────────────────────────────────────────────────

  /// Pulls every candidate `.m3u8` (and, as a last resort, `.mp4`) URL out of
  /// the page/script text, resolves relative ones against [base], dedupes and
  /// orders them so the most reliable master playlist comes first.
  List<String> _extractStreamUrls(String text, {required String base}) {
    final found = <String>{};

    // Absolute m3u8 URLs (with optional query/token).
    final absHls = RegExp(
      r'''https?:\\?/\\?/[^\s'"\\]+?\.m3u8[^\s'"\\]*''',
      caseSensitive: false,
    );
    for (final m in absHls.allMatches(text)) {
      found.add(_cleanUrl(m.group(0)!));
    }

    // Relative m3u8 URLs (e.g. hls4: "/stream/…/master.m3u8").
    final relHls = RegExp(
      r'''["'](/[^\s'"\\]+?\.m3u8[^\s'"\\]*)["']''',
      caseSensitive: false,
    );
    for (final m in relHls.allMatches(text)) {
      final rel = m.group(1)!;
      final resolved = _resolveRelative(rel, found, base);
      if (resolved != null) found.add(resolved);
    }

    // `file:"…"` blocks (JWPlayer / generic) that may not end in .m3u8.
    final fileProp = RegExp(
      r'''["']?file["']?\s*:\s*["']([^"']+)["']''',
      caseSensitive: false,
    );
    for (final m in fileProp.allMatches(text)) {
      final f = _cleanUrl(m.group(1)!);
      if (f.toLowerCase().contains('.m3u8')) {
        if (f.startsWith('http')) {
          found.add(f);
        } else if (f.startsWith('/')) {
          final resolved = _resolveRelative(f, found, base);
          if (resolved != null) found.add(resolved);
        }
      }
    }

    var list = found.where((u) => u.contains('.m3u8')).toList();

    // Fallback to mp4 if no HLS was found at all.
    if (list.isEmpty) {
      final mp4 = RegExp(
        r'''https?:\\?/\\?/[^\s'"\\]+?\.mp4[^\s'"\\]*''',
        caseSensitive: false,
      );
      for (final m in mp4.allMatches(text)) {
        found.add(_cleanUrl(m.group(0)!));
      }
      list = found.toList();
    }

    // Ordering heuristic: absolute + token-bearing "master" playlists first,
    // they're the ones that reliably play without extra auth juggling.
    list.sort((a, b) => _score(b).compareTo(_score(a)));
    return list;
  }

  int _score(String url) {
    var s = 0;
    final u = url.toLowerCase();
    if (u.startsWith('http')) s += 10;
    if (u.contains('master')) s += 5;
    if (u.contains('.m3u8')) s += 4;
    if (u.contains('token') || u.contains('t=') || u.contains('exp')) s += 3;
    if (u.contains('hls2')) s += 2; // absolute tokenized variant on many hosts
    return s;
  }

  String? _resolveRelative(String rel, Set<String> known, String base) {
    // Prefer resolving against the origin of an already-found absolute stream
    // (the real CDN host), falling back to the embed page origin.
    String? cdnBase;
    for (final k in known) {
      if (k.startsWith('http')) {
        cdnBase = _originOf(k);
        break;
      }
    }
    cdnBase ??= _originOf(base);
    try {
      return Uri.parse(cdnBase).resolve(rel).toString();
    } catch (_) {
      return null;
    }
  }

  String _cleanUrl(String url) {
    var u = url.replaceAll(r'\/', '/').replaceAll(r'\\', '');
    // Trim trailing punctuation that regexes sometimes grab.
    u = u.replaceAll(RegExp(r'[)"\';,]+$'), '');
    return u;
  }

  // ── Packed-script detection ────────────────────────────────────────────────

  /// Finds Dean-Edwards packed `eval(function(p,a,c,k,e,d){...})` bodies.
  List<String> _extractPackedBlocks(String html) {
    final blocks = <String>[];
    final marker = RegExp(r'eval\(function\(p,a,c,k,e,[dr]?\)');
    for (final m in marker.allMatches(html)) {
      final start = m.start;
      // Walk forward to the matching close of the eval( … ) call.
      final block = _sliceBalanced(html, start + 'eval'.length);
      if (block != null) blocks.add(block);
    }
    return blocks;
  }

  /// Returns the substring of the `(...)` expression starting at [openIdx]
  /// (which must point at the opening paren), balanced across nested parens.
  String? _sliceBalanced(String s, int openIdx) {
    if (openIdx >= s.length || s[openIdx] != '(') return null;
    var depth = 0;
    for (var i = openIdx; i < s.length; i++) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') {
        depth--;
        if (depth == 0) {
          return s.substring(openIdx, i + 1);
        }
      }
    }
    return null;
  }

  // ── URL helpers ─────────────────────────────────────────────────────────────

  /// Converts a "video" page URL to its "embed" variant when possible, which
  /// is where the player script usually lives (`/v/ID` → `/e/ID`).
  String _normalizeToEmbed(String url) {
    try {
      final uri = Uri.parse(url);
      final segs = List<String>.from(uri.pathSegments);
      if (segs.isNotEmpty && (segs.first == 'v' || segs.first == 'f')) {
        segs[0] = 'e';
        return uri.replace(pathSegments: segs).toString();
      }
      return url;
    } catch (_) {
      return url;
    }
  }

  String _originOf(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (_) {
      return url;
    }
  }

  Map<String, String> _baseHeaders(String url) => {
        'User-Agent': _userAgent,
        'Referer': '${_originOf(url)}/',
      };

  void clearCache() => _cache.clear();

  void dispose() => _client.close();
}

class EmbedResolveException implements Exception {
  final String message;
  EmbedResolveException(this.message);
  @override
  String toString() => 'EmbedResolveException: $message';
}

class _CachedResolution {
  final EmbedResolution resolution;
  final DateTime expiresAt;
  _CachedResolution(this.resolution, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// A self-contained Dart port of the classic Dean Edwards JavaScript
/// "P.A.C.K.E.R" unpacker (`eval(function(p,a,c,k,e,d){…})`). Used to
/// de-obfuscate player scripts before extracting stream URLs.
class JsUnpacker {
  JsUnpacker._();

  static const String _alphabet62 =
      '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

  static bool detect(String source) =>
      RegExp(r'eval\(function\(p,a,c,k,e,[dr]?\)').hasMatch(source);

  /// Unpacks a single packed block. Returns null if it can't be parsed.
  static String? unpack(String packed) {
    try {
      final args = _extractArgs(packed);
      if (args == null) return null;

      final payload = args.payload;
      final radix = args.radix;
      final count = args.count;
      final symtab = args.symtab;

      if (symtab.length != count) {
        // Some scripts pad differently; be lenient and continue.
      }

      final result = payload.replaceAllMapped(
        RegExp(r'\b\w+\b'),
        (match) {
          final word = match.group(0)!;
          final index = _unbase(word, radix);
          if (index >= 0 && index < symtab.length && symtab[index].isNotEmpty) {
            return symtab[index];
          }
          return word;
        },
      );

      // Un-escape common sequences so downstream regexes see clean URLs.
      return result.replaceAll(r'\/', '/').replaceAll(r"\'", "'");
    } catch (e) {
      debugPrint('⚠️ JsUnpacker error: $e');
      return null;
    }
  }

  static _PackerArgs? _extractArgs(String packed) {
    // Matches:  }('payload',radix,count,'a|b|c'.split('|')
    final re = RegExp(
      r"""\}\s*\(\s*'(.*)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*'(.*)'\.split\('\|'\)""",
      dotAll: true,
    );
    final m = re.firstMatch(packed);
    if (m == null) return null;

    final payload = m.group(1)!.replaceAll(r"\'", "'").replaceAll(r'\\', r'\');
    final radix = int.tryParse(m.group(2)!) ?? 36;
    final count = int.tryParse(m.group(3)!) ?? 0;
    final symtab = m.group(4)!.split('|');

    return _PackerArgs(
      payload: payload,
      radix: radix,
      count: count,
      symtab: symtab,
    );
  }

  static int _unbase(String str, int radix) {
    if (radix <= 36) {
      return int.tryParse(str, radix: radix) ?? -1;
    }
    var result = 0;
    final chars = str.split('');
    for (var i = 0; i < chars.length; i++) {
      final power = chars.length - i - 1;
      final digit = _alphabet62.indexOf(chars[i]);
      if (digit < 0) return -1;
      result += digit * math.pow(radix, power).toInt();
    }
    return result;
  }
}

class _PackerArgs {
  final String payload;
  final int radix;
  final int count;
  final List<String> symtab;
  _PackerArgs({
    required this.payload,
    required this.radix,
    required this.count,
    required this.symtab,
  });
}
