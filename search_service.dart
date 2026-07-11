/// Evento de telemetría para análisis de rendimiento
class TelemetryEvent {
  final TelemetryEventType type;
  final DateTime timestamp;
  final String channelId;
  final Map<String, dynamic> data;

  const TelemetryEvent({
    required this.type,
    required this.timestamp,
    required this.channelId,
    this.data = const {},
  });

  TelemetryEvent copyWith({
    TelemetryEventType? type,
    DateTime? timestamp,
    String? channelId,
    Map<String, dynamic>? data,
  }) {
    return TelemetryEvent(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      channelId: channelId ?? this.channelId,
      data: data ?? this.data,
    );
  }
}

enum TelemetryEventType {
  initialLoad,
  retryAttempt,
  bufferingStart,
  bufferingEnd,
  playbackStart,
  playbackEnd,
  error,
  qualityChange,
}
