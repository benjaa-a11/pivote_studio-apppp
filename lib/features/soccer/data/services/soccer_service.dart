import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class SoccerService {
  static const String _defaultApiUrl =
      'https://pivote-api.vercel.app/api/v1/live-data';
  static String? _cachedApiUrl;

  Future<String> _getApiUrl() async {
    if (_cachedApiUrl != null) return _cachedApiUrl!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('api')
          .doc('futbol')
          .get();

      if (doc.exists && doc.data() != null) {
        final url = doc.data()!['url'] as String?;
        if (url != null && url.isNotEmpty) {
          _cachedApiUrl = url;
          debugPrint('🌐 SoccerService: API URL obtenida: $url');
          return url;
        }
      }
    } catch (e) {
      debugPrint(
          'Error obteniendo URL de API desde Firestore: $e. Usando fallback.');
    }

    return _defaultApiUrl;
  }

  // === PREFETCHING OPTIMIZATION ===
  static Future<SoccerData>? _prefetchFuture;

  static void prefetchLiveSoccerData() {
    debugPrint('🚀 SoccerService: Iniciando pre-fetch en background...');
    _prefetchFuture = SoccerService()._executeFetch();
  }

  Future<SoccerData> fetchLiveSoccerData() async {
    if (_prefetchFuture != null) {
      debugPrint('⚡ SoccerService: Consumiendo data pre-cargada!');
      try {
        final data = await _prefetchFuture!;
        _prefetchFuture = null; // Clear after consumption
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
      final apiUrl = await _getApiUrl();
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SoccerData.fromJson(data);
      } else {
        throw Exception('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en SoccerService._executeFetch: $e');
      rethrow;
    }
  }
}
