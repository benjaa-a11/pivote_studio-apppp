import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pivote/features/home/data/models/app_notification.dart';

class NewsService {
  static const String _baseUrl = 'https://gnews.io/api/v4/search';
  static const String _collection = 'api';
  static const String _document = 'gnews';
  static const String _field = 'apikey';

  static Future<String?> _loadApiKey() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document)
          .get();

      final value = snapshot.data()?[_field];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      debugPrint('⚠️ GNews API key not found in api/gnews.apikey');
      return null;
    } catch (e) {
      debugPrint('❌ Error loading GNews API key from Firestore: $e');
      return null;
    }
  }

  static Future<List<AppNotification>> fetchFootballNews() async {
    final apiKey = await _loadApiKey();
    if (apiKey == null) return const [];

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': 'fútbol OR futbol OR "fútbol argentino"',
      'lang': 'es',
      'country': 'ar',
      'max': '12',
      'sortby': 'publishedAt',
      'apikey': apiKey,
    });

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('GNews API ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final articles = (data['articles'] as List? ?? const []);

      return articles
          .map((raw) {
            final article = raw as Map<String, dynamic>;
            final source = article['source'] as Map<String, dynamic>?;
            final published = DateTime.tryParse(
                  article['publishedAt'] as String? ?? '',
                ) ??
                DateTime.now();

            return AppNotification(
              id: 'news_${article['url'] ?? published.microsecondsSinceEpoch}',
              title: (article['title'] as String?)?.trim() ??
                  'Noticias de fútbol',
              body: (article['description'] as String?)?.trim() ??
                  'Últimas novedades del mundo del fútbol.',
              imageUrl: article['image'] as String?,
              deepLink: article['url'] as String?,
              source: source?['name'] as String? ?? 'Noticias',
              publishedAt: published,
              type: AppNotificationType.news,
            );
          })
          .where((item) => item.title.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching GNews: $e');
      rethrow;
    }
  }
}
