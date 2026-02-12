import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Sistema profesional de extracción de URLs de video desde embeds
/// Soporta: Sendvid, Streamtape, Doodstream, y más
class VideoExtractor {
  static const Duration _timeout = Duration(seconds: 10);
  // ignore: unused_field
  static const int _maxRedirects = 5;

  /// Extrae video_source y poster desde un embed
  static Future<ExtractedVideoData?> extractFromEmbed(String embedUrl) async {
    try {
      _log('🔍 Extrayendo desde: $embedUrl');

      // Detectar tipo de embed
      final embedType = _detectEmbedType(embedUrl);
      _log('📌 Tipo detectado: $embedType');

      switch (embedType) {
        case EmbedType.sendvid:
          return await _extractSendvid(embedUrl);
        case EmbedType.streamtape:
          return await _extractStreamtape(embedUrl);
        case EmbedType.doodstream:
          return await _extractDoodstream(embedUrl);
        case EmbedType.mixdrop:
          return await _extractMixdrop(embedUrl);
        case EmbedType.generic:
          return await _extractGeneric(embedUrl);
        default:
          _log('❌ Tipo de embed no soportado');
          return null;
      }
    } catch (e, st) {
      _log('❌ Error extrayendo video: $e\n$st');
      return null;
    }
  }

  // ═══════════════════════════════════════
  // SENDVID EXTRACTOR
  // ═══════════════════════════════════════

  static Future<ExtractedVideoData?> _extractSendvid(String embedUrl) async {
    _log('🎬 Extrayendo Sendvid...');

    final html = await _fetchHtml(embedUrl);
    if (html == null) return null;

    // Estrategia 1: Buscar var video_source = "..."
    String? videoUrl = _extractWithRegex(
      html,
      r'var\s+video_source\s*=\s*"([^"]+)"',
      'video_source',
    );

    // Estrategia 2: Buscar en <source src="...">
    videoUrl ??= _extractWithRegex(
      html,
      r'<source\s+src="([^"]+)"\s+type="video/mp4"',
      'source tag',
    );

    // Estrategia 3: Buscar en meta property og:video
    videoUrl ??= _extractWithRegex(
      html,
      r'<meta\s+property="og:video"\s+content="([^"]+)"',
      'og:video',
    );

    if (videoUrl == null) {
      _log('❌ No se encontró video_source en Sendvid');
      return null;
    }

    // Decodificar URL si está encoded
    videoUrl = Uri.decodeComponent(videoUrl);

    // Extraer poster
    String? posterUrl = _extractWithRegex(
      html,
      r'var\s+video_poster\s*=\s*"([^"]+)"',
      'video_poster',
    );

    posterUrl ??= _extractWithRegex(
      html,
      r'poster="([^"]+)"',
      'poster attribute',
    );

    posterUrl ??= _extractWithRegex(
      html,
      r'<meta\s+property="og:image"\s+content="([^"]+)"',
      'og:image',
    );

    // Extraer duración si está disponible
    final durationStr = _extractWithRegex(
      html,
      r'"duration":\s*([0-9.]+)',
      'duration',
    );

    int? durationSeconds;
    if (durationStr != null) {
      durationSeconds = double.tryParse(durationStr)?.toInt();
    }

    _log(
        '✅ Video extraído: ${videoUrl.substring(0, videoUrl.length > 60 ? 60 : videoUrl.length)}...');
    if (posterUrl != null) {
      _log(
          '🖼️ Poster encontrado: ${posterUrl.substring(0, posterUrl.length > 60 ? 60 : posterUrl.length)}...');
    }

    return ExtractedVideoData(
      videoUrl: videoUrl,
      posterUrl: posterUrl,
      embedType: EmbedType.sendvid,
      durationSeconds: durationSeconds,
      extractedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════
  // STREAMTAPE EXTRACTOR
  // ═══════════════════════════════════════

  static Future<ExtractedVideoData?> _extractStreamtape(String embedUrl) async {
    _log('🎬 Extrayendo Streamtape...');

    final html = await _fetchHtml(embedUrl);
    if (html == null) return null;

    // Streamtape usa un patrón específico
    // Buscar: document.getElementById('ideoooolink').innerHTML = '...' + '...'
    final match = RegExp(
      r"getElementById\('ideoooolink'\)\.innerHTML\s*=\s*'([^']+)'\s*\+\s*'([^']+)'",
    ).firstMatch(html);

    if (match == null) {
      _log('❌ No se encontró patrón de Streamtape');
      return null;
    }

    final part1 = match.group(1);
    final part2 = match.group(2);
    final videoUrl = 'https:$part1$part2';

    _log('✅ Video Streamtape extraído');

    return ExtractedVideoData(
      videoUrl: videoUrl,
      embedType: EmbedType.streamtape,
      extractedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════
  // DOODSTREAM EXTRACTOR
  // ═══════════════════════════════════════

  static Future<ExtractedVideoData?> _extractDoodstream(String embedUrl) async {
    _log('🎬 Extrayendo Doodstream...');

    final html = await _fetchHtml(embedUrl);
    if (html == null) return null;

    // Doodstream usa un sistema de tokens
    // Buscar el patrón: $.get('/pass_md5/...')
    final passMatch = RegExp(r"/pass_md5/([^" "'" r']+)').firstMatch(html);
    if (passMatch == null) {
      _log('❌ No se encontró pass_md5 en Doodstream');
      return null;
    }

    final passPath = passMatch.group(1)!;
    final baseUrl = Uri.parse(embedUrl);
    final passUrl = '${baseUrl.scheme}://${baseUrl.host}/pass_md5/$passPath';

    // Hacer segunda petición para obtener el token
    final token = await _fetchText(passUrl);
    if (token == null) return null;

    // Construir URL final
    final videoUrl = '$token${_generateRandomString(10)}?token=$passPath';

    _log('✅ Video Doodstream extraído');

    return ExtractedVideoData(
      videoUrl: videoUrl,
      embedType: EmbedType.doodstream,
      extractedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════
  // MIXDROP EXTRACTOR
  // ═══════════════════════════════════════

  static Future<ExtractedVideoData?> _extractMixdrop(String embedUrl) async {
    _log('🎬 Extrayendo Mixdrop...');

    final html = await _fetchHtml(embedUrl);
    if (html == null) return null;

    // Mixdrop tiene el video en un script empaquetado
    // Buscar MDCore.wurl="..."
    final videoUrl = _extractWithRegex(
      html,
      r'MDCore\.wurl="([^"]+)"',
      'MDCore.wurl',
    );

    if (videoUrl == null) {
      _log('❌ No se encontró MDCore.wurl en Mixdrop');
      return null;
    }

    final fullUrl = 'https:$videoUrl';

    _log('✅ Video Mixdrop extraído');

    return ExtractedVideoData(
      videoUrl: fullUrl,
      embedType: EmbedType.mixdrop,
      extractedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════
  // GENERIC EXTRACTOR
  // ═══════════════════════════════════════

  static Future<ExtractedVideoData?> _extractGeneric(String embedUrl) async {
    _log('🎬 Intentando extracción genérica...');

    final html = await _fetchHtml(embedUrl);
    if (html == null) return null;

    // Intentar múltiples patrones genéricos
    String? videoUrl;

    // Patrón 1: <source src="...">
    videoUrl = _extractWithRegex(
      html,
      r'<source[^>]+src="([^"]+\.(?:mp4|m3u8)[^"]*)"',
      'source tag',
    );

    // Patrón 2: <video src="...">
    videoUrl ??= _extractWithRegex(
      html,
      r'<video[^>]+src="([^"]+\.(?:mp4|m3u8)[^"]*)"',
      'video tag',
    );

    // Patrón 3: file: "..." or file: '...'
    videoUrl ??= _extractWithRegex(
      html,
      r"file:\s*[" r"']([^" r"']+\.(?:mp4|m3u8)[^" r"']*)[" r"']",
      'file property',
    );

    // Patrón 4: src: "..." or src: '...'
    videoUrl ??= _extractWithRegex(
      html,
      r"src:\s*[" r"']([^" r"']+\.(?:mp4|m3u8)[^" r"']*)[" r"']",
      'src property',
    );

    // Patrón 5: "sources":[{"file":"..."}]
    videoUrl ??= _extractWithRegex(
      html,
      r'"sources":\s*\[\s*\{\s*"file":\s*"([^"]+)"',
      'sources array',
    );

    if (videoUrl == null) {
      _log('❌ No se encontró URL de video con patrones genéricos');
      return null;
    }

    // Si la URL es relativa, completarla
    if (!videoUrl.startsWith('http')) {
      final base = Uri.parse(embedUrl);
      if (videoUrl.startsWith('//')) {
        videoUrl = '${base.scheme}:$videoUrl';
      } else if (videoUrl.startsWith('/')) {
        videoUrl = '${base.scheme}://${base.host}$videoUrl';
      }
    }

    _log('✅ Video extraído con patrón genérico');

    return ExtractedVideoData(
      videoUrl: videoUrl,
      embedType: EmbedType.generic,
      extractedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════
  // UTILIDADES
  // ═══════════════════════════════════════

  static EmbedType _detectEmbedType(String url) {
    final lowercaseUrl = url.toLowerCase();

    if (lowercaseUrl.contains('sendvid.com')) return EmbedType.sendvid;
    if (lowercaseUrl.contains('streamtape.com')) return EmbedType.streamtape;
    if (lowercaseUrl.contains('dood')) return EmbedType.doodstream;
    if (lowercaseUrl.contains('mixdrop')) return EmbedType.mixdrop;

    return EmbedType.generic;
  }

  static Future<String?> _fetchHtml(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = _timeout
        ..badCertificateCallback = ((cert, host, port) => true);

      final uri = Uri.parse(url);
      final request = await client.getUrl(uri);

      request.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      request.headers.set('Accept', 'text/html,application/xhtml+xml');
      request.headers.set('Accept-Language', 'en-US,en;q=0.9');
      request.headers.set('Referer', '${uri.scheme}://${uri.host}/');

      final response = await request.close();

      if (response.statusCode != 200) {
        _log('❌ HTTP ${response.statusCode}');
        return null;
      }

      final html = await response.transform(utf8.decoder).join();
      _log('✅ HTML descargado: ${html.length} bytes');
      return html;
    } catch (e) {
      _log('❌ Error descargando HTML: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static Future<String?> _fetchText(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = _timeout
        ..badCertificateCallback = ((cert, host, port) => true);

      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0');

      final response = await request.close();
      if (response.statusCode != 200) return null;

      return await response.transform(utf8.decoder).join();
    } catch (e) {
      _log('❌ Error en _fetchText: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }

  static String? _extractWithRegex(String html, String pattern, String name) {
    try {
      final regex = RegExp(pattern, multiLine: true, caseSensitive: false);
      final match = regex.firstMatch(html);

      if (match != null && match.groupCount >= 1) {
        final extracted = match.group(1);
        _log(
            '✓ Extraído [$name]: ${extracted?.substring(0, extracted.length > 80 ? 80 : extracted.length)}');
        return extracted;
      }

      _log('⚠️ No match para [$name]');
      return null;
    } catch (e) {
      _log('❌ Error en regex [$name]: $e');
      return null;
    }
  }

  static String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(
        length,
        (index) =>
            chars[DateTime.now().millisecondsSinceEpoch % chars.length]).join();
  }

  /// Verifica si una URL extraída todavía es válida
  static Future<bool> isUrlValid(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5)
        ..badCertificateCallback = ((cert, host, port) => true);

      final request = await client.headUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'Mozilla/5.0');

      final response = await request.close();
      await response.drain();

      return response.statusCode == 200 || response.statusCode == 206;
    } catch (e) {
      _log('⚠️ URL no válida: $e');
      return false;
    } finally {
      client?.close(force: true);
    }
  }

  static void _log(String message) {
    if (kDebugMode) {
      debugPrint('[VideoExtractor] $message');
    }
  }
}

// ═══════════════════════════════════════
// MODELOS
// ═══════════════════════════════════════

enum EmbedType {
  sendvid,
  streamtape,
  doodstream,
  mixdrop,
  generic,
  unknown,
}

class ExtractedVideoData {
  final String videoUrl;
  final String? posterUrl;
  final EmbedType embedType;
  final int? durationSeconds;
  final DateTime extractedAt;

  ExtractedVideoData({
    required this.videoUrl,
    this.posterUrl,
    required this.embedType,
    this.durationSeconds,
    required this.extractedAt,
  });

  /// Verifica si la extracción sigue siendo válida (dentro de 4 horas)
  bool get isStillValid {
    final elapsed = DateTime.now().difference(extractedAt);
    return elapsed.inHours < 4;
  }

  /// Tiempo restante antes de que expire (aprox)
  Duration get timeUntilExpiry {
    final elapsed = DateTime.now().difference(extractedAt);
    final remaining = const Duration(hours: 4) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() => {
        'videoUrl': videoUrl,
        'posterUrl': posterUrl,
        'embedType': embedType.toString(),
        'durationSeconds': durationSeconds,
        'extractedAt': extractedAt.toIso8601String(),
      };

  factory ExtractedVideoData.fromJson(Map<String, dynamic> json) {
    return ExtractedVideoData(
      videoUrl: json['videoUrl'],
      posterUrl: json['posterUrl'],
      embedType: EmbedType.values.firstWhere(
        (e) => e.toString() == json['embedType'],
        orElse: () => EmbedType.unknown,
      ),
      durationSeconds: json['durationSeconds'],
      extractedAt: DateTime.parse(json['extractedAt']),
    );
  }

  @override
  String toString() {
    return 'ExtractedVideoData{videoUrl: ${videoUrl.substring(0, videoUrl.length > 50 ? 50 : videoUrl.length)}..., embedType: $embedType, valid: $isStillValid}';
  }
}
