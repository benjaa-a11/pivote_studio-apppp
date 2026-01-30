import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/soccer_models.dart';

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

  Future<MatchDetailData> fetchMatchDetail(String detailsPath) async {
    try {
      // Remove leading slash if present in detailsPath
      final path =
          detailsPath.startsWith('/') ? detailsPath.substring(1) : detailsPath;
      final fullUrl = 'https://pivote-api.vercel.app/$path';

      final response = await http.get(Uri.parse(fullUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return MatchDetailData.fromJson(data);
      } else {
        throw Exception(
            'Error al cargar detalles del partido: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error en fetchMatchDetail: $e');
      rethrow;
    }
  }
}
