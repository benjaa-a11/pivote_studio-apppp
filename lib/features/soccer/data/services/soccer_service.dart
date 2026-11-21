import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/core/services/app_remote_config_service.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class SoccerService {
  // === PREFETCHING OPTIMIZATION ===
  static Future<SoccerData>? _prefetchFuture;

  /// Pre-carga partidos únicamente cuando la sesión activa y `config/app` están listos.
  static void prefetchLiveSoccerData() {
    debugPrint('🚀 SoccerService: Iniciando pre-fetch de partidos de hoy...');
    final future = SoccerService()._executeFetch(date: 'today');
    _prefetchFuture = future;
    unawaited(future.then((_) {}, onError: (Object e) {
      debugPrint('⚠️ SoccerService: Pre-fetch en background falló: $e');
      if (identical(_prefetchFuture, future)) {
        _prefetchFuture = null;
      }
    }));
  }

  static void resetPrefetch() {
    _prefetchFuture = null;
  }

  Future<SoccerData> fetchLiveSoccerData() => fetchMatches(date: 'today');

  Future<SoccerData> fetchMatches({String date = 'today'}) async {
    if (date == 'today' && _prefetchFuture != null) {
      debugPrint('⚡ SoccerService: Consumiendo data pre-cargada!');
      try {
        final data = await _prefetchFuture!;
        _prefetchFuture = null;
        return data;
      } catch (e) {
        _prefetchFuture = null;
        debugPrint('⚠️ Pre-fetch falló, re-intentando: $e');
        return _executeFetch(date: date);
      }
    }
    return _executeFetch(date: date);
  }

  Future<String> _requireMatchesBaseUrl() async {
    if (!AppRemoteConfigService.isLoaded) {
      await AppRemoteConfigService.load();
    }
    final url = AppRemoteConfigService.matchesApiUrl;
    if (url == null || url.isEmpty) {
      throw Exception(
        'Falta configurar `matchesApiUrl` en Firestore (colección `config`, doc `app`).',
      );
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<http.Response> _authorizedGet(String url) async {
    final headers = await AppRemoteConfigService.buildAuthorizedHeaders(
      extra: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    );

    if (kIsWeb) {
      try {
        return await http
            .get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 12));
      } catch (_) {
        final proxyBase = AppRemoteConfigService.webProxyUrl;
        if (proxyBase == null || proxyBase.isEmpty) rethrow;
        final sep = proxyBase.contains('?') ? '&' : '?';
        final proxiedUrl =
            '$proxyBase${sep}url=${Uri.encodeComponent(url)}';
        return await http
            .get(Uri.parse(proxiedUrl), headers: headers)
            .timeout(const Duration(seconds: 12));
      }
    }

    return await http
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 12));
  }

  Future<SoccerData> _executeFetch({String date = 'today'}) async {
    try {
      final baseUrl = await _requireMatchesBaseUrl();
      final url = '$baseUrl?date=${Uri.encodeQueryComponent(date)}';
      final response = await _authorizedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        return SoccerData.fromJson(decoded);
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en SoccerService._executeFetch($date): $e');
      rethrow;
    }
  }

  Future<SoccerMatchDetail> fetchMatchDetail(String matchId) async {
    try {
      final baseUrl = await _requireMatchesBaseUrl();
      final url = '$baseUrl/${Uri.encodeComponent(matchId)}';
      final response = await _authorizedGet(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        return SoccerMatchDetail.fromJson(decoded);
      } else {
        throw Exception('Error al cargar detalle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en SoccerService.fetchMatchDetail($matchId): $e');
      rethrow;
    }
  }
}
