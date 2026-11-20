import 'js_deobfuscator.dart';
import 'resolver_models.dart';

// ════════════════════════════════════════════════════════════════════════════
// StreamCandidateExtractor — Recolección + puntuación de URLs de stream
// ════════════════════════════════════════════════════════════════════════════
//
// En vez de quedarse con "el primer regex que matchea" (frágil: suele agarrar
// publicidad, trackers P2P o streams de prueba), se recolectan TODOS los
// candidatos de todas las fuentes (HTML plano, HTML desescapado, JS
// desofuscado, packer, base64...) y se ordenan por puntuación.

class StreamCandidateExtractor {
  StreamCandidateExtractor._();

  /// Claves JS/JSON que normalmente contienen la URL de reproducción.
  static const _strongKeys = {
    'playbackurl', 'playback_url', 'src', 'source', 'sources', 'file', 'hls',
    'hlsurl', 'hls_url', 'stream', 'streamurl', 'stream_url', 'streamsrc',
    'm3u8', 'manifest', 'manifesturl', 'videourl', 'video_url', 'videosrc',
    'url', 'live', 'liveurl', 'sourceurl', 'source_url', 'playlist', 'link',
    'fuente', 'canal',
  };

  /// Hosts que nunca son el stream (publicidad, analítica, CDNs de librerías,
  /// trackers P2P...).
  static const _blockedHostFragments = [
    'histats', 'jsdelivr', 'googleapis', 'gstatic', 'google-analytics',
    'googletagmanager', 'doubleclick', 'googlesyndication', 'adservice',
    'adcash', 'aclib', 'profiton', 'adsterra', 'monetag', 'popads', 'propeller',
    'facebook', 'fbcdn', 'twitter', 'cloudflareinsights', 'swarmcloud',
    'cdnpeer', 'unpkg', 'cdnjs', 'jquery', 'bootstrapcdn', 'fontawesome',
    'hotjar', 'yandex', 'disqus', 'onesignal', 'tracker', 'p2p-engine',
  ];

  /// Streams de demostración embebidos como "fallback" en muchos players.
  static const _demoStreamFragments = [
    'test-streams.mux.dev', 'bitdash-a.akamaihd.net', 'bigbuckbunny',
    'sintel', 'tears-of-steel', 'demo.unified-streaming', 'devstreaming-cdn.apple',
  ];

  static const _assetExtensions = [
    '.js', '.css', '.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp', '.ico',
    '.woff', '.woff2', '.ttf', '.json', '.xml', '.txt', '.vtt', '.srt',
  ];

  static final _reKeyValue = RegExp(
    r'''["']?([A-Za-z_$][\w$]*)["']?\s*[:=]\s*["']((?:https?:)?//[^"'\s<>\\]+|/[^"'\s<>\\]+)["']''',
  );
  static final _reGenericAbs = RegExp(
    r'''(?:https?:)?//[^\s"'<>\\()\[\]{}]+?\.(?:m3u8|mpd)(?:\?[^\s"'<>\\()\[\]{}]*)?''',
    caseSensitive: false,
  );
  static final _reQuotedRelative = RegExp(
    r'''["']([^"'\s<>]+?\.(?:m3u8|mpd)(?:\?[^"'\s<>]*)?)["']''',
    caseSensitive: false,
  );
  static final _reHtmlMediaTag = RegExp(
    r'''<(?:source|video)\b[^>]*?\bsrc\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  );

  // ── API ───────────────────────────────────────────────────────────────────

  /// Devuelve candidatos ordenados de mayor a menor puntuación.
  static List<StreamCandidate> extract(String html, Uri pageUri) {
    final found = <String, StreamCandidate>{};

    void add(String rawUrl, String strategy, {String? key, int bonus = 0}) {
      final url = _normalize(rawUrl, pageUri);
      if (url == null) return;
      final score = scoreUrl(url, key: key) + bonus;
      final existing = found[url];
      if (existing == null || existing.score < score) {
        found[url] = StreamCandidate(url: url, score: score, strategy: strategy, key: key);
      }
    }

    final unescaped = JsDeobfuscator.unescapeJs(html);
    final texts = <String>{html, unescaped};

    // 1. JS desofuscado (lo más fiable cuando existe: nadie ofusca publicidad)
    for (final frag in JsDeobfuscator.decodeAll(html)) {
      final text = JsDeobfuscator.unescapeJs(frag.text).trim();
      final varName = frag.varName?.toLowerCase();
      final isAdVar = varName != null &&
          RegExp(r'ads?|referral|pop|banner|promo|track').hasMatch(varName);

      if (_looksLikeAbsoluteUrl(text) && !text.contains(' ')) {
        var bonus = isAdVar ? -80 : 25;
        if (varName != null && _strongKeys.contains(varName)) bonus += 20;
        if (varName != null && RegExp(r'play|stream|src|source|hls|m3u|video|file').hasMatch(varName)) {
          bonus += 15;
        }
        add(text, frag.technique, key: frag.varName, bonus: bonus);
      } else {
        texts.add(text);
      }
    }

    // 2. Escaneo de patrones en todos los textos
    for (final text in texts) {
      _scanText(text, add);
    }

    final list = found.values.where((c) => c.score > 0).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// iframes / redirecciones JS hacia otro reproductor (para resolución anidada).
  static List<Uri> findEmbeddedFrames(String html, Uri pageUri) {
    final out = <Uri>[];
    final seen = <String>{pageUri.toString()};
    final patterns = [
      RegExp(r'''<iframe\b[^>]*?\b(?:data-)?src\s*=\s*["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''(?:window\.)?location(?:\.href)?\s*=\s*["']([^"']+)["']'''),
      RegExp(r'''location\.replace\(\s*["']([^"']+)["']\s*\)'''),
      RegExp(r'''\.src\s*=\s*["']([^"']+\.(?:php|html?)(?:\?[^"']*)?)["']'''),
    ];
    final unescaped = JsDeobfuscator.unescapeJs(html);
    for (final re in patterns) {
      for (final m in re.allMatches(unescaped)) {
        final raw = m.group(1)!.trim();
        if (raw.isEmpty || raw.startsWith('about:') || raw.startsWith('javascript:') || raw.startsWith('#')) {
          continue;
        }
        final lower = raw.toLowerCase();
        if (lower.contains('block.html') || lower.contains('/ads') || lower.contains('adblock')) continue;
        final url = _normalize(raw, pageUri);
        if (url == null || !seen.add(url)) continue;
        final uri = Uri.tryParse(url);
        if (uri == null || _isBlockedHost(uri.host)) continue;
        out.add(uri);
      }
    }
    return out;
  }

  // ── Puntuación ────────────────────────────────────────────────────────────

  static int scoreUrl(String url, {String? key}) {
    final lower = url.toLowerCase();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return -1000;
    final path = uri.path.toLowerCase();

    var score = 0;
    if (_isBlockedHost(uri.host)) score -= 300;
    if (_demoStreamFragments.any(lower.contains)) score -= 120;

    if (path.endsWith('.m3u8') || lower.contains('.m3u8')) {
      score += 60;
    } else if (path.endsWith('.mpd')) {
      score += 45;
    } else if (lower.contains('chunklist') || lower.contains('/hls/') || lower.contains('playlist.m3u')) {
      score += 35;
    } else if (path.endsWith('.ts') || path.endsWith('.mp4') || path.endsWith('.flv')) {
      score += 15;
    } else if (path.endsWith('.php')) {
      score += 5;
    }

    if (!lower.contains('.m3u8') && _assetExtensions.any(path.endsWith)) score -= 200;
    if (path.endsWith('.html') || path.endsWith('.htm')) score -= 60;

    if (RegExp(r'[?&](token|tk|sig|signature|expires?|exp|hdnts|hdnea|auth|md5|hash|st|e|s|wmsauthsign|key|session)=')
        .hasMatch(lower)) {
      score += 15;
    }
    if (RegExp(r'/(ads?|vast|vpaid|preroll|advert|banner|promo)[/._-]').hasMatch(lower)) score -= 70;

    if (key != null && _strongKeys.contains(key.toLowerCase())) score += 15;
    if (uri.scheme == 'https') score += 2;
    return score;
  }

  // ── Internos ──────────────────────────────────────────────────────────────

  static void _scanText(
    String text,
    void Function(String url, String strategy, {String? key, int bonus}) add,
  ) {
    for (final m in _reKeyValue.allMatches(text)) {
      final key = m.group(1)!;
      final url = m.group(2)!;
      final lower = url.toLowerCase();
      final streamy = lower.contains('.m3u8') ||
          lower.contains('.mpd') ||
          lower.contains('chunklist') ||
          lower.contains('/hls/');
      if (streamy || (_strongKeys.contains(key.toLowerCase()) && _maybeStreamEndpoint(lower))) {
        add(url, 'player-config', key: key);
      }
    }
    for (final m in _reHtmlMediaTag.allMatches(text)) {
      add(m.group(1)!, 'html-media', bonus: 10);
    }
    for (final m in _reGenericAbs.allMatches(text)) {
      add(m.group(0)!, 'generic');
    }
    for (final m in _reQuotedRelative.allMatches(text)) {
      final raw = m.group(1)!;
      if (raw.startsWith('http') || raw.startsWith('//')) continue;
      add(raw, 'relative', bonus: -5);
    }
  }

  /// Endpoints sin extensión que suelen devolver el manifiesto (ej. `get.php?id=`).
  static bool _maybeStreamEndpoint(String lower) {
    if (_assetExtensions.any((e) => Uri.tryParse(lower)?.path.endsWith(e) ?? false)) return false;
    return lower.contains('m3u') ||
        lower.contains('stream') ||
        lower.contains('live') ||
        lower.contains('hls') ||
        lower.contains('playlist') ||
        lower.contains('manifest');
  }

  static bool _looksLikeAbsoluteUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://') || s.startsWith('//');

  static bool _isBlockedHost(String host) {
    final h = host.toLowerCase();
    return _blockedHostFragments.any(h.contains);
  }

  static String? _normalize(String raw, Uri base) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'''[)\]}>;,'"\\]+$'''), '');
    s = s.replaceAll('&amp;', '&');
    try {
      final uri = s.startsWith('//') ? Uri.parse('${base.scheme}:$s') : base.resolve(s);
      if (uri.scheme != 'http' && uri.scheme != 'https') return null;
      if (uri.host.isEmpty) return null;
      return uri.toString();
    } catch (_) {
      return null;
    }
  }
}
