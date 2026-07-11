/// Representa una URL resuelta con metadatos de resolución
class ResolvedURL {
  final String finalURL;
  final DateTime resolvedAt;
  final Duration resolutionTime;
  final bool fromCache;

  const ResolvedURL({
    required this.finalURL,
    required this.resolvedAt,
    required this.resolutionTime,
    required this.fromCache,
  });

  ResolvedURL copyWith({
    String? finalURL,
    DateTime? resolvedAt,
    Duration? resolutionTime,
    bool? fromCache,
  }) {
    return ResolvedURL(
      finalURL: finalURL ?? this.finalURL,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionTime: resolutionTime ?? this.resolutionTime,
      fromCache: fromCache ?? this.fromCache,
    );
  }
}
