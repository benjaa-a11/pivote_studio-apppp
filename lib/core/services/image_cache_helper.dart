import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Servicio centralizado de caché de imágenes para toda la app.
///
/// Provee:
/// - [customCacheManager]: Manager principal con User-Agent personalizado (evita bloqueos CDN)
/// - [logoCacheManager]: Manager optimizado para logos pequeños (escudos, radios, canales)
/// - [warmUpCache]: Pre-carga imágenes en background para evitar el "primer arranque lento"
/// - [configurePaintingCache]: Configura el caché de imágenes en RAM de Flutter
class ImageCacheHelper {
  static const String _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36';

  /// Manager principal para imágenes de alta calidad (posters, fondos)
  /// - 500 objetos en caché
  /// - 30 días de retención (logos/imágenes rara vez cambian)
  static final CacheManager customCacheManager = CacheManager(
    Config(
      'pivote_custom_cache_v2',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: 'pivote_custom_cache_v2'),
      fileService: HttpFileService(
        httpClient: _UserAgentClient(http.Client(), _userAgent),
      ),
    ),
  );

  /// Manager especializado para logos pequeños (escudos, radios, canales)
  /// Configurado con retención máxima — estos logos cambian muy raramente.
  static final CacheManager logoCacheManager = CacheManager(
    Config(
      'pivote_logo_cache_v2',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 1000,
      repo: JsonCacheInfoRepository(databaseName: 'pivote_logo_cache_v2'),
      fileService: HttpFileService(
        httpClient: _UserAgentClient(http.Client(), _userAgent),
      ),
    ),
  );

  /// Configura los límites del caché de imágenes en RAM de Flutter.
  /// Debe llamarse una sola vez al inicio de la app (en main()).
  ///
  /// Por defecto Flutter solo guarda 100 MB → con muchos logos se expulsan
  /// imágenes de la RAM → aparecen y desaparecen en la UI.
  static void configurePaintingCache() {
    // 2000 imágenes en RAM (default: 1000)
    PaintingBinding.instance.imageCache.maximumSize = 2000;
    // 300 MB en RAM (default: 100 MB)
    PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
    debugPrint('✅ Flutter image cache configurado: 2000 imgs / 300 MB');
  }

  /// Pre-carga una lista de URLs en el caché en background usando [logoCacheManager].
  /// No bloquea la UI — las requests corren en paralelo de forma silenciosa.
  ///
  /// Usar [isLogos] = true para logos/escudos pequeños (default),
  /// false para imágenes grandes como posters de películas.
  static void warmUpCache(List<String> urls, {bool isLogos = true}) {
    if (urls.isEmpty) return;
    final manager = isLogos ? logoCacheManager : customCacheManager;

    // Filtrar URLs inválidas y limitar para no sobrecargar la red
    final urlsToPreload = urls
        .where((url) => url.isNotEmpty && url.startsWith('http'))
        .take(80)
        .toList();

    if (urlsToPreload.isEmpty) return;
    debugPrint('🔥 Pre-cargando ${urlsToPreload.length} imágenes en background...');

    for (final url in urlsToPreload) {
      // ignore: unawaited_futures
      (() async {
        try {
          await manager.getSingleFile(url);
        } catch (_) {}
      })();
    }
  }
}

/// Cliente HTTP que inyecta un User-Agent personalizado en todas las requests.
/// Necesario para evitar que CDNs bloqueen las peticiones del cliente Dart por defecto.
class _UserAgentClient extends http.BaseClient {
  final http.Client _inner;
  final String _userAgent;

  _UserAgentClient(this._inner, this._userAgent);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    request.headers['accept'] = 'image/webp,image/apng,image/*,*/*;q=0.8';
    request.headers['accept-language'] = 'es-AR,es;q=0.9,en;q=0.8';
    return _inner.send(request);
  }
}
