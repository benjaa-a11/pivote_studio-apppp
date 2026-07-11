/// Información sobre un intento de conexión
class RetryAttempt {
  final String server;
  final int attemptNumber;
  final DateTime timestamp;
  final Duration timeout;
  final bool success;
  final String? errorMessage;
  final Duration? responseTime;

  const RetryAttempt({
    required this.server,
    required this.attemptNumber,
    required this.timestamp,
    required this.timeout,
    required this.success,
    this.errorMessage,
    this.responseTime,
  });

  RetryAttempt copyWith({
    String? server,
    int? attemptNumber,
    DateTime? timestamp,
    Duration? timeout,
    bool? success,
    String? errorMessage,
    Duration? responseTime,
  }) {
    return RetryAttempt(
      server: server ?? this.server,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      timestamp: timestamp ?? this.timestamp,
      timeout: timeout ?? this.timeout,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      responseTime: responseTime ?? this.responseTime,
    );
  }
}
