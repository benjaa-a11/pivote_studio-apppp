import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class SoccerService {
  static const String apiUrl =
      'https://apipro-pivo.provip.workers.dev/api/v1/live';

  // === PREFETCHING OPTIMIZATION ===
  static Future<SoccerData>? _prefetchFuture;

  static void prefetchLiveSoccerData() {
    debugPrint('🚀 SoccerService: Iniciando pre-fetch en background...');
    final future = SoccerService()._executeFetch();
    _prefetchFuture = future;
    unawaited(future.then((_) {}, onError: (Object e) {
      debugPrint('⚠️ SoccerService: Pre-fetch en background falló: $e');
      if (identical(_prefetchFuture, future)) {
        _prefetchFuture = null;
      }
    }));
  }

  Future<SoccerData> fetchLiveSoccerData() async {
    if (_prefetchFuture != null) {
      debugPrint('⚡ SoccerService: Consumiendo data pre-cargada!');
      try {
        final data = await _prefetchFuture!;
        _prefetchFuture = null;
        return data;
      } catch (e) {
        _prefetchFuture = null;
        debugPrint('⚠️ Pre-fetch falló, re-intentando: $e');
        return _executeFetch();
      }
    }
    return _executeFetch();
  }

  Future<SoccerData> _executeFetch() async {
    try {
      http.Response response;
      if (kIsWeb) {
        try {
          response = await http
              .get(Uri.parse(apiUrl))
              .timeout(const Duration(seconds: 12));
        } catch (_) {
          final proxiedUrl =
              'https://myproxy.canalesonline24.workers.dev/?url=${Uri.encodeComponent(apiUrl)}';
          response = await http
              .get(Uri.parse(proxiedUrl))
              .timeout(const Duration(seconds: 12));
        }
      } else {
        response = await http.get(
          Uri.parse(apiUrl),
          headers: const {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        ).timeout(const Duration(seconds: 12));
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        return SoccerData.fromJson(decoded);
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en SoccerService._executeFetch: $e');
      rethrow;
    }
  }
}
