import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_extractor.dart';

/// Gestor profesional de fuentes de video con caché inteligente
/// Maneja URLs temporales, re-extracción automática y múltiples servidores
class VideoSourceManager {
  static const String _cachePrefix = 'video_cache_';
  static const Duration _cacheValidity = Duration(hours: 3);

  final SharedPreferences _prefs;
  final Map<String, ExtractedVideoData> _memoryCache = {};

  VideoSourceManager(this._prefs);

  static Future<VideoSourceManager> create() async {
    final prefs = await SharedPreferences.getInstance();
    return VideoSourceManager(prefs);
  }

  // ═══════════════════════════════════════
  // OBTENCIÓN DE FUENTES
  // ═══════════════════════════════════════

  /// Obtiene la URL de video desde un embed, usando caché si está disponible
  Future<VideoSourceResult> getVideoSource(String embedUrl) async {
    try {
      _log('🔍 Obteniendo fuente para: $embedUrl');

      // 1. Verificar caché en memoria
      final memoryCached = _memoryCache[embedUrl];
      if (memoryCached != null && memoryCached.isStillValid) {
        _log('✅ Usando caché en memoria');
        return VideoSourceResult.success(
          memoryCached,
          source: SourceOrigin.memoryCache,
        );
      }

      // 2. Verificar caché persistente
      final diskCached = await _getFromDiskCache(embedUrl);
      if (diskCached != null && diskCached.isStillValid) {
        _log('✅ Usando caché en disco');
        _memoryCache[embedUrl] = diskCached;
        return VideoSourceResult.success(
          diskCached,
          source: SourceOrigin.diskCache,
        );
      }

      // 3. Caché expiró o no existe, extraer nuevamente
      _log('🔄 Extrayendo nueva URL...');
      final extracted = await VideoExtractor.extractFromEmbed(embedUrl);

      if (extracted == null) {
        return VideoSourceResult.failure('No se pudo extraer la URL del video');
      }

      // 4. Guardar en ambos cachés
      _memoryCache[embedUrl] = extracted;
      await _saveToDiskCache(embedUrl, extracted);

      _log('✅ Extracción exitosa y guardada en caché');
      return VideoSourceResult.success(
        extracted,
        source: SourceOrigin.freshExtraction,
      );
    } catch (e, st) {
      _log('❌ Error obteniendo fuente: $e\n$st');
      return VideoSourceResult.failure('Error: $e');
    }
  }

  /// Obtiene múltiples fuentes (para contenido con varios servidores)
  Future<MultiSourceResult> getMultipleSources(List<String> embedUrls) async {
    _log('🔍 Obteniendo ${embedUrls.length} fuentes...');

    final results = <VideoSourceResult>[];
    final successfulSources = <ExtractedVideoData>[];

    for (var i = 0; i < embedUrls.length; i++) {
      final result = await getVideoSource(embedUrls[i]);
      results.add(result);

      if (result.isSuccess) {
        successfulSources.add(result.data!);
        _log('✅ Servidor ${i + 1}/${embedUrls.length} OK');
      } else {
        _log('❌ Servidor ${i + 1}/${embedUrls.length} falló');
      }
    }

    return MultiSourceResult(
      allResults: results,
      successfulSources: successfulSources,
      failedCount: embedUrls.length - successfulSources.length,
    );
  }

  // ═══════════════════════════════════════
  // REVALIDACIÓN
  // ═══════════════════════════════════════

  /// Revalida una URL y la re-extrae si es necesario
  Future<VideoSourceResult> revalidateSource(String embedUrl) async {
    _log('🔄 Revalidando fuente...');

    final cached = _memoryCache[embedUrl] ?? await _getFromDiskCache(embedUrl);

    if (cached == null) {
      return await getVideoSource(embedUrl);
    }

    // Si todavía es válida por tiempo, verificar que la URL funcione
    if (cached.isStillValid) {
      final urlValid = await VideoExtractor.isUrlValid(cached.videoUrl);
      if (urlValid) {
        _log('✅ URL todavía válida');
        return VideoSourceResult.success(cached,
            source: SourceOrigin.memoryCache);
      }
    }

    // URL expiró o no funciona, re-extraer
    _log('⚠️ URL expiró, re-extrayendo...');
    _memoryCache.remove(embedUrl);
    await _removeFromDiskCache(embedUrl);

    return await getVideoSource(embedUrl);
  }

  // ═══════════════════════════════════════
  // CACHÉ EN DISCO
  // ═══════════════════════════════════════

  Future<ExtractedVideoData?> _getFromDiskCache(String embedUrl) async {
    try {
      final key = _cacheKey(embedUrl);
      final jsonStr = _prefs.getString(key);

      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final data = ExtractedVideoData.fromJson(json);

      // Verificar si no ha expirado
      final age = DateTime.now().difference(data.extractedAt);
      if (age > _cacheValidity) {
        _log('⚠️ Caché expiró (${age.inHours}h)');
        await _removeFromDiskCache(embedUrl);
        return null;
      }

      return data;
    } catch (e) {
      _log('❌ Error leyendo caché: $e');
      return null;
    }
  }

  Future<void> _saveToDiskCache(
      String embedUrl, ExtractedVideoData data) async {
    try {
      final key = _cacheKey(embedUrl);
      final jsonStr = jsonEncode(data.toJson());
      await _prefs.setString(key, jsonStr);
      _log('💾 Guardado en caché: $key');
    } catch (e) {
      _log('❌ Error guardando en caché: $e');
    }
  }

  Future<void> _removeFromDiskCache(String embedUrl) async {
    try {
      final key = _cacheKey(embedUrl);
      await _prefs.remove(key);
    } catch (e) {
      _log('❌ Error eliminando caché: $e');
    }
  }

  String _cacheKey(String embedUrl) {
    return '$_cachePrefix${embedUrl.hashCode}';
  }

  // ═══════════════════════════════════════
  // LIMPIEZA
  // ═══════════════════════════════════════

  /// Limpia todo el caché (memoria y disco)
  Future<void> clearAllCache() async {
    _memoryCache.clear();

    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys.where((k) => k.startsWith(_cachePrefix));

    for (final key in cacheKeys) {
      await _prefs.remove(key);
    }

    _log('🗑️ Caché limpiado');
  }

  /// Limpia solo el caché expirado
  Future<void> clearExpiredCache() async {
    final now = DateTime.now();

    // Limpiar memoria
    _memoryCache.removeWhere((key, value) {
      final age = now.difference(value.extractedAt);
      return age > _cacheValidity;
    });

    // Limpiar disco
    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys.where((k) => k.startsWith(_cachePrefix));

    for (final key in cacheKeys) {
      try {
        final jsonStr = _prefs.getString(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final data = ExtractedVideoData.fromJson(json);
          final age = now.difference(data.extractedAt);

          if (age > _cacheValidity) {
            await _prefs.remove(key);
            _log('🗑️ Caché expirado eliminado: $key');
          }
        }
      } catch (e) {
        // Si hay error, eliminar la entrada corrupta
        await _prefs.remove(key);
      }
    }

    _log('🗑️ Caché expirado limpiado');
  }

  // ═══════════════════════════════════════
  // ESTADÍSTICAS
  // ═══════════════════════════════════════

  /// Obtiene estadísticas del caché
  Future<CacheStats> getStats() async {
    final allKeys = _prefs.getKeys();
    final cacheKeys = allKeys.where((k) => k.startsWith(_cachePrefix)).toList();

    int validCount = 0;
    int expiredCount = 0;
    final now = DateTime.now();

    for (final key in cacheKeys) {
      try {
        final jsonStr = _prefs.getString(key);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final data = ExtractedVideoData.fromJson(json);
          final age = now.difference(data.extractedAt);

          if (age <= _cacheValidity) {
            validCount++;
          } else {
            expiredCount++;
          }
        }
      } catch (e) {
        expiredCount++;
      }
    }

    return CacheStats(
      memoryCount: _memoryCache.length,
      diskCount: cacheKeys.length,
      validCount: validCount,
      expiredCount: expiredCount,
    );
  }
}

// ═══════════════════════════════════════
// RESULTADOS
// ═══════════════════════════════════════

enum SourceOrigin {
  memoryCache,
  diskCache,
  freshExtraction,
}

class VideoSourceResult {
  final ExtractedVideoData? data;
  final String? error;
  final SourceOrigin? source;

  VideoSourceResult._({
    this.data,
    this.error,
    this.source,
  });

  factory VideoSourceResult.success(
    ExtractedVideoData data, {
    required SourceOrigin source,
  }) {
    return VideoSourceResult._(data: data, source: source);
  }

  factory VideoSourceResult.failure(String error) {
    return VideoSourceResult._(error: error);
  }

  bool get isSuccess => data != null;
  bool get isFailure => error != null;

  @override
  String toString() {
    if (isSuccess) {
      return 'VideoSourceResult.success(source: $source, data: $data)';
    }
    return 'VideoSourceResult.failure(error: $error)';
  }
}

class MultiSourceResult {
  final List<VideoSourceResult> allResults;
  final List<ExtractedVideoData> successfulSources;
  final int failedCount;

  MultiSourceResult({
    required this.allResults,
    required this.successfulSources,
    required this.failedCount,
  });

  bool get hasAnySources => successfulSources.isNotEmpty;
  int get successCount => successfulSources.length;
  int get totalCount => allResults.length;

  ExtractedVideoData? get primary =>
      successfulSources.isNotEmpty ? successfulSources.first : null;

  @override
  String toString() {
    return 'MultiSourceResult(total: $totalCount, success: $successCount, failed: $failedCount)';
  }
}

class CacheStats {
  final int memoryCount;
  final int diskCount;
  final int validCount;
  final int expiredCount;

  CacheStats({
    required this.memoryCount,
    required this.diskCount,
    required this.validCount,
    required this.expiredCount,
  });

  @override
  String toString() {
    return 'CacheStats(memory: $memoryCount, disk: $diskCount, valid: $validCount, expired: $expiredCount)';
  }
}

void _log(String message) {
  if (kDebugMode) {
    debugPrint('[VideoSourceManager] $message');
  }
}
