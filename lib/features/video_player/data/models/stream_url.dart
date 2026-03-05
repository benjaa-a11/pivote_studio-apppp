/// Representa una URL de streaming con metadatos asociados
class StreamURL {
  final String rawURL;
  final String resolvedURL;
  final StreamType type;
  final DateTime? cachedAt;
  final Duration? resolutionTime;

  const StreamURL({
    required this.rawURL,
    required this.resolvedURL,
    required this.type,
    this.cachedAt,
    this.resolutionTime,
  });

  bool get isCached => cachedAt != null;

  bool get isExpired =>
      cachedAt != null &&
      DateTime.now().difference(cachedAt!) > const Duration(minutes: 5);

  StreamURL copyWith({
    String? rawURL,
    String? resolvedURL,
    StreamType? type,
    DateTime? cachedAt,
    Duration? resolutionTime,
  }) {
    return StreamURL(
      rawURL: rawURL ?? this.rawURL,
      resolvedURL: resolvedURL ?? this.resolvedURL,
      type: type ?? this.type,
      cachedAt: cachedAt ?? this.cachedAt,
      resolutionTime: resolutionTime ?? this.resolutionTime,
    );
  }
}

enum StreamType { m3u8, dash, iframe, external }
