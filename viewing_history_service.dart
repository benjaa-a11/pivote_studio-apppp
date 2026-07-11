import 'buffer_state.dart';
import 'video_quality.dart';

/// Estado completo del reproductor de video
class PlayerState {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final BufferState bufferState;
  final double volume;
  final bool isMuted;
  final VideoQuality? quality;
  final List<PlayerError> errors;

  const PlayerState({
    required this.status,
    required this.position,
    required this.duration,
    required this.bufferState,
    required this.volume,
    required this.isMuted,
    this.quality,
    this.errors = const [],
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isBuffering => status == PlaybackStatus.buffering;

  PlayerState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    BufferState? bufferState,
    double? volume,
    bool? isMuted,
    VideoQuality? quality,
    List<PlayerError>? errors,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferState: bufferState ?? this.bufferState,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      quality: quality ?? this.quality,
      errors: errors ?? this.errors,
    );
  }
}

enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
}

class PlayerError {
  final String message;
  final String? code;
  final DateTime timestamp;

  const PlayerError({
    required this.message,
    this.code,
    required this.timestamp,
  });
}
