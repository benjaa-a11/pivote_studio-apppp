import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pivote/features/home/data/models/app_notification.dart';

class NewsService {
  static const String _baseUrl = 'https://gnews.io/api/v4/search';

  // Configure this at build time with --dart-define=GNEWS_API_KEY=...
  static const String _apiKey = String.fromEnvironment('GNEWS_API_KEY');

  static Future<List<AppNotification>> fetchFootballNews() async {
    if (_apiKey.isEmpty) return const [];

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': 'fútbol OR futbol OR fútbol argentino',
      'lang': 'es',
      'country': 'ar',
      'max': '12',
      'sortby': 'publishedAt',
      'apikey': _apiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('News API ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final articles = (data['articles'] as List? ?? const []);

    return articles.map((raw) {
      final article = raw as Map<String, dynamic>;
      final source = article['source'] as Map<String, dynamic>?;
      final published = DateTime.tryParse(article['publishedAt'] as String? ?? '') ?? DateTime.now();
      return AppNotification(
        id: 'news_${article['url'] ?? published.microsecondsSinceEpoch}',
        title: (article['title'] as String?)?.trim() ?? 'Noticias de fútbol',
        body: (article['description'] as String?)?.trim() ?? 'Últimas novedades del mundo del fútbol.',
        imageUrl: article['image'] as String?,
        deepLink: article['url'] as String?,
        source: source?['name'] as String? ?? 'Noticias',
        publishedAt: published,
        type: AppNotificationType.news,
      );
    }).where((item) => item.title.isNotEmpty).toList();
  }
}
