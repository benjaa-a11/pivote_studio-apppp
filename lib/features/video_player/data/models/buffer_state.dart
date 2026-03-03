/// Estado del buffer del reproductor
class BufferState {
  final Duration buffered;
  final Duration target;
  final bool isHealthy;
  final double fillPercentage;

  const BufferState({
    required this.buffered,
    required this.target,
    required this.isHealthy,
    required this.fillPercentage,
  });

  BufferState copyWith({
    Duration? buffered,
    Duration? target,
    bool? isHealthy,
    double? fillPercentage,
  }) {
    return BufferState(
      buffered: buffered ?? this.buffered,
      target: target ?? this.target,
      isHealthy: isHealthy ?? this.isHealthy,
      fillPercentage: fillPercentage ?? this.fillPercentage,
    );
  }
}
