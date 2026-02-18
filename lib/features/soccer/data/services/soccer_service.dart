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
          debugPrint('URL de API de fútbol obtenida desde Firestore: $url');
          return url;
        }
      }
    } catch (e) {
      debugPrint(
          'Error obteniendo URL de API desde Firestore: $e. Usando fallback.');
    }

    return _defaultApiUrl;
  }

  Future<SoccerData> fetchLiveSoccerData() async {
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
      debugPrint('Error en SoccerService: $e');
      rethrow;
    }
  }
}
