import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/soccer/data/models/soccer_models.dart';

class SoccerService {
  static const String apiUrl = 'https://pivote-api.vercel.app/api/v1/live-data';

  Future<SoccerData> fetchLiveSoccerData() async {
    try {
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
