import 'resolved_url.dart';

/// Entrada cacheada con timestamp para gestión de expiración
class CachedEntry {
  final ResolvedURL value;
  final DateTime timestamp;

  const CachedEntry({
    required this.value,
    required this.timestamp,
  });

  bool isExpired(Duration ttl) {
    return DateTime.now().difference(timestamp) > ttl;
  }
}

/// Caché de URLs resueltas con TTL de 5 minutos
///
/// Gestiona el almacenamiento temporal de URLs resueltas para evitar
/// resoluciones repetidas dentro del período de TTL.
///
/// **Validates: Requirements 1.4**
class URLCache {
  final Duration ttl;
  final Map<String, CachedEntry> _cache = {};

  URLCache({this.ttl = const Duration(minutes: 5)});

  /// Almacena una URL resuelta en el caché
  ///
  /// [key] es la URL original sin resolver
  /// [value] es la URL resuelta con metadatos
  void put(String key, ResolvedURL value) {
    _cache[key] = CachedEntry(
      value: value,
      timestamp: DateTime.now(),
    );
  }

  /// Obtiene una URL del caché si existe y no ha expirado
  ///
  /// Retorna null si la URL no está en caché o ha expirado.
  /// Las entradas expiradas se eliminan automáticamente.
  ResolvedURL? get(String key) {
    final entry = _cache[key];

    if (entry == null) {
      return null;
    }

    if (entry.isExpired(ttl)) {
      _cache.remove(key);
      return null;
    }

    return entry.value;
  }

  /// Limpia todas las entradas del caché
  void clear() {
    _cache.clear();
  }

  /// Limpia solo las entradas expiradas del caché
  void clearExpired() {
    _cache.removeWhere((key, entry) => entry.isExpired(ttl));
  }

  /// Retorna el número de entradas en el caché (incluyendo expiradas)
  int get size => _cache.length;

  /// Retorna el número de entradas válidas (no expiradas) en el caché
  int get validSize {
    return _cache.values.where((entry) => !entry.isExpired(ttl)).length;
  }
}
