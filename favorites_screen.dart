/// Representa un evento de seguridad para logging y análisis
class SecurityEvent {
  final SecurityEventType type;
  final SecurityLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const SecurityEvent({
    required this.type,
    required this.level,
    required this.message,
    required this.timestamp,
    this.metadata = const {},
  });

  bool get isCritical => level == SecurityLevel.critical;

  SecurityEvent copyWith({
    SecurityEventType? type,
    SecurityLevel? level,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityEvent(
      type: type ?? this.type,
      level: level ?? this.level,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum SecurityEventType {
  sslValidationFailed,
  certificatePinningFailed,
  urlBlacklisted,
  injectionAttempt,
  unauthorizedCommand,
  tokenExpired,
  deviceCompromised,
}

enum SecurityLevel {
  debug,
  info,
  warning,
  error,
  critical,
}
