enum AppNotificationType { news, match, goal, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? deepLink;
  final String source;
  final DateTime publishedAt;
  final AppNotificationType type;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    required this.type,
    this.imageUrl,
    this.deepLink,
    this.source = 'Pivote',
    this.isRead = false,
  });

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      deepLink: deepLink,
      source: source,
      publishedAt: publishedAt,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }
}
