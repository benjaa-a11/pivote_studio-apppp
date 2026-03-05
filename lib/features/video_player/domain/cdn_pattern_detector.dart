/// Detector de patrones CDN conocidos para optimización de resolución de URLs
///
/// Identifica URLs que pertenecen a CDNs conocidos (Cloudflare, Akamai, AWS CloudFront)
/// para omitir verificaciones HEAD/GET innecesarias y mejorar el rendimiento.
///
/// **Validates: Requirements 1.3**
class CDNPatternDetector {
  // Patrones de dominio para Cloudflare
  static final List<RegExp> _cloudflarePatterns = [
    RegExp(r'\.cloudflare\.com$', caseSensitive: false),
    RegExp(r'\.cloudflare\.net$', caseSensitive: false),
    RegExp(r'\.cloudflarestream\.com$', caseSensitive: false),
    RegExp(r'\.cloudfront\.net$',
        caseSensitive: false), // AWS CloudFront también usa este dominio
  ];

  // Patrones de dominio para Akamai
  static final List<RegExp> _akamaiPatterns = [
    RegExp(r'\.akamai\.net$', caseSensitive: false),
    RegExp(r'\.akamaihd\.net$', caseSensitive: false),
    RegExp(r'\.akamaized\.net$', caseSensitive: false),
    RegExp(r'\.akamaitechnologies\.com$', caseSensitive: false),
  ];

  // Patrones de dominio para AWS CloudFront
  static final List<RegExp> _cloudfrontPatterns = [
    RegExp(r'\.cloudfront\.net$', caseSensitive: false),
    RegExp(r'\.amazonaws\.com$', caseSensitive: false),
  ];

  /// Detecta si una URL pertenece a un CDN conocido
  ///
  /// Retorna true si la URL coincide con patrones de Cloudflare, Akamai o AWS CloudFront.
  /// Esto permite al sistema omitir verificaciones HEAD/GET adicionales.
  ///
  /// Ejemplo:
  /// ```dart
  /// final detector = CDNPatternDetector();
  /// detector.isKnownCDN('https://video.cloudflare.com/stream.m3u8'); // true
  /// detector.isKnownCDN('https://example.com/video.m3u8'); // false
  /// ```
  bool isKnownCDN(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      // Verificar patrones de Cloudflare
      if (_matchesAnyPattern(host, _cloudflarePatterns)) {
        return true;
      }

      // Verificar patrones de Akamai
      if (_matchesAnyPattern(host, _akamaiPatterns)) {
        return true;
      }

      // Verificar patrones de AWS CloudFront
      if (_matchesAnyPattern(host, _cloudfrontPatterns)) {
        return true;
      }

      return false;
    } catch (e) {
      // Si la URL no es válida, retornar false
      return false;
    }
  }

  /// Detecta el tipo de CDN de una URL
  ///
  /// Retorna el nombre del CDN ('cloudflare', 'akamai', 'cloudfront') o null si no es un CDN conocido.
  String? detectCDNType(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      if (_matchesAnyPattern(host, _cloudflarePatterns)) {
        return 'cloudflare';
      }

      if (_matchesAnyPattern(host, _akamaiPatterns)) {
        return 'akamai';
      }

      if (_matchesAnyPattern(host, _cloudfrontPatterns)) {
        return 'cloudfront';
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Verifica si un host coincide con alguno de los patrones proporcionados
  bool _matchesAnyPattern(String host, List<RegExp> patterns) {
    return patterns.any((pattern) => pattern.hasMatch(host));
  }
}
