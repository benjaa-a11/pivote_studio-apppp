import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pivote/features/home/data/models/app_notification.dart';

class NewsService {
  static const String _baseUrl = 'https://newsdata.io/api/1/latest';
  static const String _apiKey = 'pub_0ca293f34dec4079be9b27f81f5fe8e5';

  static Future<List<AppNotification>> fetchFootballNews() async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: const {
      'apikey': _apiKey,
      'q': 'futbol noticias argentina',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('NewsData HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'NewsData devolvió un error');
    }

    final articles = (data['results'] as List?) ?? const [];
    final notifications = <AppNotification>[];

    for (final raw in articles) {
      if (raw is! Map<String, dynamic>) continue;
      final title = (raw['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) continue;

      final published = DateTime.tryParse(
            (raw['pubDate'] as String?)?.replaceFirst(' ', 'T') ?? '',
          ) ??
          DateTime.now();
      final description = (raw['description'] as String?)?.trim();
      final content = (raw['content'] as String?)?.trim();
      final body = description?.isNotEmpty == true
          ? description!
          : content?.isNotEmpty == true
              ? content!
              : 'Últimas noticias del fútbol argentino.';

      notifications.add(
        AppNotification(
          id: 'newsdata_${raw['article_id'] ?? raw['link'] ?? title.hashCode}',
          title: title,
          body: body,
          imageUrl: (raw['image_url'] as String?)?.trim(),
          deepLink: null,
          source: (raw['source_name'] as String?)?.trim() ?? 'NewsData',
          publishedAt: published,
          type: AppNotificationType.news,
        ),
      );
    }

    notifications.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return notifications;
  }
}
