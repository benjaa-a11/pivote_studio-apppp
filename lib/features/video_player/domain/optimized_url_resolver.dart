import 'dart:async';
import 'dart:io';

import 'cdn_pattern_detector.dart';
import 'resolved_url.dart';
import 'url_cache.dart';

/// Resuelve URLs de streaming con optimizaciones de caché y detección inteligente
/// 
/// Este componente implementa múltiples optimizaciones para reducir el tiempo
/// de carga inicial de streams:
/// - Detección de URLs M3U8 directas para omitir resolución HTTP
/// - Detección de patrones CDN conocidos para omitir verificaciones
/// - Caché de URLs resueltas con TTL de 5 minutos
/// - Timeout reducido de 8 segundos en primer intento de conexión
/// 
/// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
class OptimizedURLResolver {
  final URLCache _cache;
  final CDNPatternDetector _cdnDetector;
  final HttpClient _httpClient;

  OptimizedURLResolver({
    URLCache? cache,
    CDNPatternDetector? cdnDetector,
    HttpClient? httpClient,
  })  : _cache = cache ?? URLCache(),
        _cdnDetector = cdnDetector ?? CDNPatternDetector(),
        _httpClient = httpClient ?? HttpClient();

  /// Verifica si una URL es directamente utilizable como M3U8 sin resolución
  /// 
  /// Una URL se considera M3U8 directa si:
  /// - Contiene la extensión .m3u8 en el path
  /// - Contiene parámetros que indican formato M3U8
  /// 
  /// Ejemplo:
  /// ```dart
  /// resolver.isDirectM3U8URL('https://cdn.com/stream.m3u8'); // true
  /// resolver.isDirectM3U8URL('https://cdn.com/stream.m3u8?token=abc'); // true
  /// resolver.isDirectM3U8URL('https://cdn.com/stream'); // false
  /// ```
  /// 
  /// **Validates: Requirements 1.2**
  bool isDirectM3U8URL(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      
      // Verificar extensión .m3u8 en el path
      if (path.endsWith('.m3u8')) {
        return true;
      }
      
      // Verificar parámetros que indican M3U8
      final queryParams = uri.queryParameters;
      if (queryParams.containsKey('m3u8') || 
          queryParams.containsKey('format') && 
          queryParams['format']?.toLowerCase() == 'm3u8') {
        return true;
      }
      
      return false;
    } catch (e) {
      // Si la URL no es válida, no es una URL M3U8 directa
      return false;
    }
  }

  /// Resuelve una URL de streaming con optimizaciones
  /// 
  /// El proceso de resolución incluye:
  /// 1. Verificar si la URL está en caché (retorna inmediatamente si existe)
  /// 2. Verificar si es una URL M3U8 directa (omite resolución HTTP)
  /// 3. Verificar si es un CDN conocido (omite verificaciones HEAD/GET)
  /// 4. Si requiere resolución, realiza solicitud HTTP con timeout de 8 segundos
  /// 5. Cachea el resultado exitoso para futuras solicitudes
  /// 
  /// [rawURL] es la URL original a resolver
  /// [timeout] es el tiempo máximo de espera (default: 8 segundos)
  /// [skipResolution] fuerza omitir la resolución HTTP
  /// 
  /// Retorna un [ResolvedURL] con la URL final y metadatos de resolución.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final resolved = await resolver.resolveStreamURL(
  ///   'https://example.com/stream',
  ///   timeout: Duration(seconds: 8),
  /// );
  /// print('Final URL: ${resolved.finalURL}');
  /// print('From cache: ${resolved.fromCache}');
  /// ```
  /// 
  /// **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
  Future<ResolvedURL> resolveStreamURL(
    String rawURL, {
    Duration timeout = const Duration(seconds: 8),
    bool skipResolution = false,
  }) async {
    final startTime = DateTime.now();

    // 1. Verificar caché primero (Requirement 1.4)
    final cached = _cache.get(rawURL);
    if (cached != null) {
      return cached.copyWith(fromCache: true);
    }

    // 2. Verificar si es URL M3U8 directa (Requirement 1.2)
    if (isDirectM3U8URL(rawURL)) {
      final resolved = ResolvedURL(
        finalURL: rawURL,
        resolvedAt: startTime,
        resolutionTime: DateTime.now().difference(startTime),
        fromCache: false,
      );
      _cache.put(rawURL, resolved);
      return resolved;
    }

    // 3. Verificar si es CDN conocido (Requirement 1.3)
    if (_cdnDetector.isKnownCDN(rawURL)) {
      final resolved = ResolvedURL(
        finalURL: rawURL,
        resolvedAt: startTime,
        resolutionTime: DateTime.now().difference(startTime),
        fromCache: false,
      );
      _cache.put(rawURL, resolved);
      return resolved;
    }

    // 4. Si se solicita omitir resolución, retornar URL original
    if (skipResolution) {
      final resolved = ResolvedURL(
        finalURL: rawURL,
        resolvedAt: startTime,
        resolutionTime: DateTime.now().difference(startTime),
        fromCache: false,
      );
      _cache.put(rawURL, resolved);
      return resolved;
    }

    // 5. Realizar resolución HTTP con timeout (Requirement 1.5)
    try {
      final resolvedURL = await _resolveHTTP(rawURL, timeout);
      final resolved = ResolvedURL(
        finalURL: resolvedURL,
        resolvedAt: startTime,
        resolutionTime: DateTime.now().difference(startTime),
        fromCache: false,
      );
      _cache.put(rawURL, resolved);
      return resolved;
    } catch (e) {
      // En caso de error, retornar la URL original
      // Esto permite que el reproductor intente con la URL original
      final resolved = ResolvedURL(
        finalURL: rawURL,
        resolvedAt: startTime,
        resolutionTime: DateTime.now().difference(startTime),
        fromCache: false,
      );
      return resolved;
    }
  }

  /// Realiza resolución HTTP con timeout
  /// 
  /// Intenta seguir redirects HTTP para obtener la URL final del stream.
  /// Usa un timeout de 8 segundos por defecto (Requirement 1.5).
  Future<String> _resolveHTTP(String url, Duration timeout) async {
    final uri = Uri.parse(url);
    
    try {
      final request = await _httpClient.headUrl(uri).timeout(timeout);
      request.followRedirects = true;
      
      final response = await request.close().timeout(timeout);
      
      // Si hay redirects, la URL final está en response.redirects
      if (response.redirects.isNotEmpty) {
        final lastRedirect = response.redirects.last;
        return lastRedirect.location.toString();
      }
      
      // Si no hay redirects, retornar la URL original
      return url;
    } catch (e) {
      // En caso de timeout u otro error, lanzar excepción
      rethrow;
    }
  }

  /// Cachea una URL resuelta exitosamente
  /// 
  /// Útil para cachear URLs resueltas externamente.
  void cacheResolvedURL(String rawURL, ResolvedURL resolved) {
    _cache.put(rawURL, resolved);
  }

  /// Obtiene una URL del caché si está disponible
  /// 
  /// Retorna null si la URL no está en caché o ha expirado.
  ResolvedURL? getCachedURL(String rawURL) {
    return _cache.get(rawURL);
  }

  /// Limpia el caché de URLs
  void clearCache() {
    _cache.clear();
  }

  /// Limpia solo las entradas expiradas del caché
  void clearExpiredCache() {
    _cache.clearExpired();
  }

  /// Cierra el cliente HTTP y libera recursos
  void dispose() {
    _httpClient.close();
  }
}
