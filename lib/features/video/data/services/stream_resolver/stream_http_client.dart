import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pivote/features/video/data/models/channel.dart';

import 'stream_token_inspector.dart';

// ════════════════════════════════════════════════════════════════════════════
// StreamHttpClient — Cliente HTTP resiliente con evasión de antibots y
// soporte de TLS permisivo, compresión (gzip/deflate/br) y redirecciones.
// ════════════════════════════════════════════════════════════════════════════

class HttpResponseInfo {
  final int statusCode;
  final String body;
  final Uri finalUri;
  final Map<String, String> headers;
  final List<String> redirectChain;

  const HttpResponseInfo({
    required this.statusCode,
    required this.body,
    required this.finalUri,
    required this.headers,
    this.redirectChain = const [],
  });

  String? get contentType => headers['content-type'];
  DateTime? get date => StreamTokenInspector.parseHttpDate(headers['date']);
}

class StreamHttpClient {
  StreamHttpClient._();

  static const Duration requestTimeout = Duration(seconds: 12);
  static const int maxRedirects = 8;

  /// User-Agent Android moderno (crucial para sitios como la18hd que bloquean desktop o curl).
  static const String mobileChromeUa =
      'Mozilla/5.0 (Linux; Android 13; SM-A536B) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36';

  static const String desktopChromeUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36';

  /// Descarga el contenido HTML/texto de una página resolviendo redirecciones y
  /// configurando cabeceras de navegación realista.
  static Future<HttpResponseInfo?> fetchPage(
    String url, {
    Map<String, String>? customHeaders,
    bool preferMobileUa = true,
  }) async {
    if (kIsWeb) return null;
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = requestTimeout
        ..idleTimeout = requestTimeout
        ..badCertificateCallback = (_, __, ___) => true;

      var currentUri = Uri.parse(url);
      final redirects = <String>[];
      int redirectCount = 0;

      while (redirectCount < maxRedirects) {
        final req = await client.getUrl(currentUri);
        req.followRedirects = false; // Manejo manual para capturar URLs intermedias y .m3u8

        final ua = customHeaders?['User-Agent'] ??
            (preferMobileUa ? mobileChromeUa : desktopChromeUa);

        req.headers
          ..set('User-Agent', ua)
          ..set(
            'Accept',
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          )
          ..set('Accept-Language', 'es-AR,es;q=0.9,en;q=0.8')
          ..set('Accept-Encoding', 'gzip, deflate')
          ..set('Connection', 'keep-alive')
          ..set('Upgrade-Insecure-Requests', '1')
          ..set('Sec-Fetch-Dest', 'iframe')
          ..set('Sec-Fetch-Mode', 'navigate')
          ..set('Sec-Fetch-Site', 'cross-site');

        // Referer & Origin adaptativos
        final referer = customHeaders?['Referer'] ?? '${currentUri.scheme}://${currentUri.host}/';
        req.headers.set('Referer', referer);
        req.headers.set('Origin', customHeaders?['Origin'] ?? '${currentUri.scheme}://${currentUri.host}');

        // Añadir cabeceras personalizadas adicionales si existen
        if (customHeaders != null) {
          customHeaders.forEach((k, v) {
            if (!k.startsWith('Sec-') && !k.startsWith('Accept-')) {
              req.headers.set(k, v);
            }
          });
        }

        final res = await req.close().timeout(requestTimeout);
        final statusCode = res.statusCode;

        // Si es redirección (301, 302, 303, 307, 308)
        if (statusCode == 301 ||
            statusCode == 302 ||
            statusCode == 303 ||
            statusCode == 307 ||
            statusCode == 308) {
          final location = res.headers.value(HttpHeaders.locationHeader);
          await res.drain<void>();
          if (location == null || location.isEmpty) break;

          final nextUri = currentUri.resolve(location);
          redirects.add(nextUri.toString());

          // Si en la redirección ya saltó directamente a un .m3u8/.mpd, terminar aquí
          final locLower = nextUri.toString().toLowerCase();
          if (locLower.contains('.m3u8') || locLower.contains('.mpd')) {
            return HttpResponseInfo(
              statusCode: statusCode,
              body: '',
              finalUri: nextUri,
              headers: _extractHeaders(res),
              redirectChain: redirects,
            );
          }

          currentUri = nextUri;
          redirectCount++;
          continue;
        }

        final body = await _readResponseBody(res);
        return HttpResponseInfo(
          statusCode: statusCode,
          body: body ?? '',
          finalUri: currentUri,
          headers: _extractHeaders(res),
          redirectChain: redirects,
        );
      }
      return null;
    } catch (e) {
      debugPrint('🌐 StreamHttpClient error fetching $url: $e');
      return null;
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
    }
  }

  /// Verifica activamente si un candidato .m3u8 / .mpd responde 200 OK y entrega
  /// un manifiesto válido (#EXTM3U / <MPD) o un redireccionamiento válido.
  static Future<CandidateVerification?> verifyStreamCandidate(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kIsWeb) return null;
    HttpClient? client;
    try {
      client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6)
        ..idleTimeout = const Duration(seconds: 6)
        ..badCertificateCallback = (_, __, ___) => true;

      var uri = Uri.parse(url);
      final req = await client.getUrl(uri);
      req.followRedirects = true;
      req.maxRedirects = 5;

      final smart = StreamSource.resolveSmartHeaders(url, headers) ?? const {};
      req.headers
        ..set('User-Agent', smart['User-Agent'] ?? mobileChromeUa)
        ..set('Accept', '*/*')
        ..set('Connection', 'keep-alive');

      if (smart.containsKey('Referer')) req.headers.set('Referer', smart['Referer']!);
      if (smart.containsKey('Origin')) req.headers.set('Origin', smart['Origin']!);

      final res = await req.close().timeout(const Duration(seconds: 7));
      final finalUrl = res.redirects.isNotEmpty
          ? res.redirects.last.location.toString()
          : url;

      final ct = res.headers.contentType?.mimeType.toLowerCase() ?? '';
      final isStreamMime = ct.contains('mpegurl') ||
          ct.contains('dash+xml') ||
          ct.contains('octet-stream');

      if (res.statusCode == 200) {
        // Leer primeros 2 KB para comprobar cabecera #EXTM3U o <MPD
        final chunk = await res.take(2048).fold<List<int>>(
              [],
              (prev, el) => prev..addAll(el),
            );
        final snippet = utf8.decode(chunk, allowMalformed: true).trimLeft();

        final isValidManifest = snippet.startsWith('#EXTM3U') ||
            snippet.contains('<MPD') ||
            snippet.contains('#EXT-X-') ||
            isStreamMime;

        return CandidateVerification(
          finalUrl: finalUrl,
          statusCode: res.statusCode,
          isValidManifest: isValidManifest,
          serverDate: StreamTokenInspector.parseHttpDate(res.headers.value(HttpHeaders.dateHeader)),
        );
      } else {
        await res.drain<void>();
        return CandidateVerification(
          finalUrl: finalUrl,
          statusCode: res.statusCode,
          isValidManifest: false,
        );
      }
    } catch (_) {
      return null;
    } finally {
      try {
        client?.close(force: true);
      } catch (_) {}
    }
  }

  static Future<String?> _readResponseBody(HttpClientResponse res) async {
    try {
      final bytes = await res.fold<List<int>>([], (prev, el) => prev..addAll(el));
      try {
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        return latin1.decode(bytes);
      }
    } catch (e) {
      debugPrint('❌ _readResponseBody error: $e');
      return null;
    }
  }

  static Map<String, String> _extractHeaders(HttpClientResponse res) {
    final map = <String, String>{};
    res.headers.forEach((name, values) {
      map[name.toLowerCase()] = values.join(', ');
    });
    return map;
  }
}

class CandidateVerification {
  final String finalUrl;
  final int statusCode;
  final bool isValidManifest;
  final DateTime? serverDate;

  const CandidateVerification({
    required this.finalUrl,
    required this.statusCode,
    required this.isValidManifest,
    this.serverDate,
  });
}
