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

  AppNotification copyWith({bool? isRead}) => AppNotification(
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'deepLink': deepLink,
        'source': source,
        'publishedAt': publishedAt.toIso8601String(),
        'type': type.name,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'system';
    final type = AppNotificationType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => AppNotificationType.system,
    );

    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Pivote',
      body: json['body'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      deepLink: json['deepLink'] as String?,
      source: json['source'] as String? ?? 'Pivote',
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ?? DateTime.now(),
      type: type,
    );
  }
}
