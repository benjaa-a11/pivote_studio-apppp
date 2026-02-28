import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'dart:async';

/// Unified interface for all video controllers with professional state management
abstract class UnifiedVideoController {
  bool get isPlaying;
  bool get isBuffering;
  bool get isInitialized;
  bool get isMuted;
  Duration get position;
  Duration get duration;
  double get volume;
  int get bufferHealth; // 0-100
  bool get hasError;
  String? get errorMessage;

  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double volume);
  Future<void> setMuted(bool muted);
  Future<void> retry();

  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  void dispose();

  factory UnifiedVideoController.fromVideoPlayer(
      VideoPlayerController controller) {
    return HLSControllerAdapter(controller);
  }

  factory UnifiedVideoController.fromWeb(
      WebViewController controller, VideoState state) {
    return WebControllerAdapter(controller, state);
  }
}

/// Enhanced State object with complete video information
class VideoState {
  bool isPlaying = false;
  bool isBuffering = false;
  bool isMuted = false;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;

  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  double volume = 1.0;

  int bufferHealth = 100;
  bool stallDetected = false;
  int serverIndex = 0;
  int totalServers = 0;
  String? channelId;

  DateTime lastUpdate = DateTime.now();

  final List<VoidCallback> listeners = [];
  final StreamController<VideoStateChange> _stateChangeController =
      StreamController<VideoStateChange>.broadcast();

  Stream<VideoStateChange> get stateChanges => _stateChangeController.stream;

  void notify() {
    lastUpdate = DateTime.now();
    for (var listener in listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('⚠️ Error en listener: $e');
      }
    }
  }

  void addListener(VoidCallback listener) {
    if (!listeners.contains(listener)) {
      listeners.add(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void update({
    bool? playing,
    bool? buffering,
    bool? muted,
    bool? loading,
    bool? error,
    String? errorMsg,
    double? pos,
    double? dur,
    double? vol,
    int? bufHealth,
    bool? stalled,
    int? servIndex,
    int? totalServ,
    String? chanId,
  }) {
    final changes = <String, dynamic>{};

    if (playing != null && playing != isPlaying) {
      changes['isPlaying'] = playing;
      isPlaying = playing;
    }
    if (buffering != null && buffering != isBuffering) {
      changes['isBuffering'] = buffering;
      isBuffering = buffering;
    }
    if (muted != null && muted != isMuted) {
      changes['isMuted'] = muted;
      isMuted = muted;
    }
    if (loading != null && loading != isLoading) {
      changes['isLoading'] = loading;
      isLoading = loading;
    }
    if (error != null && error != hasError) {
      changes['hasError'] = error;
      hasError = error;
    }
    if (errorMsg != null) {
      changes['errorMessage'] = errorMsg;
      errorMessage = errorMsg;
    }
    if (pos != null) {
      position = Duration(milliseconds: (pos * 1000).toInt());
    }
    if (dur != null) {
      duration = Duration(milliseconds: (dur * 1000).toInt());
    }
    if (vol != null && vol != volume) {
      changes['volume'] = vol;
      volume = vol;
    }
    if (bufHealth != null && bufHealth != bufferHealth) {
      changes['bufferHealth'] = bufHealth;
      bufferHealth = bufHealth;
    }
    if (stalled != null && stalled != stallDetected) {
      changes['stallDetected'] = stalled;
      stallDetected = stalled;
    }
    if (servIndex != null) serverIndex = servIndex;
    if (totalServ != null) totalServers = totalServ;
    if (chanId != null) channelId = chanId;

    if (changes.isNotEmpty) {
      _stateChangeController.add(VideoStateChange(changes));
    }

    notify();
  }

  void reset() {
    update(
      playing: false,
      buffering: false,
      loading: true,
      error: false,
      errorMsg: null,
      pos: 0,
      dur: 0,
      bufHealth: 100,
      stalled: false,
    );
  }

  void dispose() {
    listeners.clear();
    _stateChangeController.close();
  }

  Map<String, dynamic> toMap() {
    return {
      'isPlaying': isPlaying,
      'isBuffering': isBuffering,
      'isMuted': isMuted,
      'isLoading': isLoading,
      'hasError': hasError,
      'errorMessage': errorMessage,
      'position': position.inMilliseconds,
      'duration': duration.inMilliseconds,
      'volume': volume,
      'bufferHealth': bufferHealth,
      'stallDetected': stallDetected,
      'serverIndex': serverIndex,
      'totalServers': totalServers,
      'channelId': channelId,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }
}

/// State change event
class VideoStateChange {
  final Map<String, dynamic> changes;
  final DateTime timestamp;

  VideoStateChange(this.changes) : timestamp = DateTime.now();

  bool hasChanged(String key) => changes.containsKey(key);

  T? getValue<T>(String key) => changes[key] as T?;
}

/// Adapter for HLS VideoPlayerController with enhanced error handling
class HLSControllerAdapter implements UnifiedVideoController {
  final VideoPlayerController controller;
  Timer? _errorCheckTimer;
  bool _disposed = false;

  HLSControllerAdapter(this.controller) {
    _startErrorMonitoring();
  }

  void _startErrorMonitoring() {
    _errorCheckTimer?.cancel();
    _errorCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      // Monitor for errors
      if (controller.value.hasError) {
        debugPrint(
            '⚠️ HLS Error detected: ${controller.value.errorDescription}');
      }
    });
  }

  @override
  bool get isPlaying => controller.value.isPlaying;

  @override
  bool get isBuffering => controller.value.isBuffering;

  @override
  bool get isInitialized => controller.value.isInitialized;

  @override
  bool get isMuted => controller.value.volume == 0.0;

  @override
  Duration get position => controller.value.position;

  @override
  Duration get duration => controller.value.duration;

  @override
  double get volume => controller.value.volume;

  @override
  int get bufferHealth {
    try {
      if (!controller.value.isInitialized) return 0;

      final buffered = controller.value.buffered;
      if (buffered.isEmpty) return 0;

      final currentPosMs = position.inMilliseconds;
      for (final range in buffered) {
        if (range.start.inMilliseconds <= currentPosMs &&
            currentPosMs <= range.end.inMilliseconds) {
          final bufferAheadSeconds =
              (range.end.inMilliseconds - currentPosMs) / 1000.0;
          // Map buffer seconds to 0-100 health score
          // healthyBufferSeconds (5s) = 100%, 0s = 0%
          return ((bufferAheadSeconds / PlayerConfig.healthyBufferSeconds) *
                  100)
              .clamp(0, 100)
              .toInt();
        }
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Real seconds of buffer ahead of current position
  Duration get bufferAhead {
    try {
      if (!controller.value.isInitialized) return Duration.zero;
      final buffered = controller.value.buffered;
      if (buffered.isEmpty) return Duration.zero;
      final currentPosMs = position.inMilliseconds;
      for (final range in buffered) {
        if (range.start.inMilliseconds <= currentPosMs &&
            currentPosMs <= range.end.inMilliseconds) {
          return Duration(
              milliseconds: range.end.inMilliseconds - currentPosMs);
        }
      }
      return Duration.zero;
    } catch (e) {
      return Duration.zero;
    }
  }

  @override
  bool get hasError => controller.value.hasError;

  @override
  String? get errorMessage => controller.value.errorDescription;

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> setVolume(double volume) =>
      controller.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> setMuted(bool muted) => controller.setVolume(muted ? 0.0 : 1.0);

  @override
  Future<void> retry() async {
    // For HLS, we need to reinitialize
    debugPrint('🔄 HLS Retry requested');
    // This should be handled at widget level
  }

  @override
  void addListener(void Function() listener) =>
      controller.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      controller.removeListener(listener);

  @override
  void dispose() {
    _disposed = true;
    _errorCheckTimer?.cancel();
  }
}

/// Enhanced Adapter for WebViewController with better sync
class WebControllerAdapter implements UnifiedVideoController {
  final WebViewController controller;
  final VideoState state;
  Timer? _syncTimer;
  bool _disposed = false;

  WebControllerAdapter(this.controller, this.state) {
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      _requestStateUpdate();
    });
  }

  Future<void> _requestStateUpdate() async {
    try {
      await controller.runJavaScript('''
        (function() {
          if (window.FlutterBridge && window.getPlayerState) {
            window.FlutterBridge.sendStateUpdate();
          }
        })();
      ''');
    } catch (e) {
      debugPrint('⚠️ Error requesting state update: $e');
    }
  }

  @override
  bool get isPlaying => state.isPlaying;

  @override
  bool get isBuffering => state.isBuffering;

  @override
  bool get isInitialized => !state.isLoading;

  @override
  bool get isMuted => state.isMuted;

  @override
  Duration get position => state.position;

  @override
  Duration get duration => state.duration;

  @override
  double get volume => state.volume;

  @override
  int get bufferHealth => state.bufferHealth;

  @override
  bool get hasError => state.hasError;

  @override
  String? get errorMessage => state.errorMessage;

  @override
  Future<void> play() => _executeJS("window.play()", "Play error");

  @override
  Future<void> pause() => _executeJS("window.pause()", "Pause error");

  @override
  Future<void> setVolume(double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    state.volume = clampedVolume;
    return _executeJS("window.setVolume($clampedVolume)", "SetVolume error");
  }

  @override
  Future<void> setMuted(bool muted) {
    state.isMuted = muted;
    return _executeJS(
        muted ? "window.mute()" : "window.unmute()", "SetMuted error");
  }

  @override
  Future<void> retry() =>
      _executeJS("window.retryCurrentServer()", "Retry error");

  Future<void> _executeJS(String script, String errorContext) async {
    try {
      await controller.runJavaScript('''
        (function() {
          try {
            $script;
          } catch(e) {
            console.log('$errorContext:', e);
          }
        })();
      ''');
    } catch (e) {
      debugPrint('❌ $errorContext: $e');
    }
  }

  @override
  void addListener(void Function() listener) => state.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      state.removeListener(listener);

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
  }
}
