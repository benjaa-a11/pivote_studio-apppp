import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pivote/features/video/presentation/widgets/iptv_engine.dart';

// ════════════════════════════════════════════════════════════════════════════
// Unified Video Controller — abstraction over IPTVEngine + WebView
// ════════════════════════════════════════════════════════════════════════════

abstract class UnifiedVideoController {
  bool get isPlaying;
  bool get isBuffering;
  bool get isInitialized;
  bool get isMuted;
  Duration get position;
  Duration get duration;
  double get volume;
  int get bufferHealth;
  bool get hasError;
  String? get errorMessage;

  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double v);
  Future<void> setMuted(bool muted);
  Future<void> retry();

  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  void dispose();

  factory UnifiedVideoController.fromIPTV(IPTVEngine engine) =>
      _IPTVControllerAdapter(engine);

  factory UnifiedVideoController.fromWeb(
          WebViewController controller, VideoState state) =>
      _WebControllerAdapter(controller, state);
}

// ── IPTV Adapter (media_kit) ──────────────────────────────────────────────

class _IPTVControllerAdapter implements UnifiedVideoController {
  final IPTVEngine _engine;

  _IPTVControllerAdapter(this._engine);

  @override
  bool get isPlaying => _engine.state.isPlaying;
  @override
  bool get isBuffering => _engine.state.isBuffering;
  @override
  bool get isInitialized =>
      _engine.state.status != IPTVStatus.idle &&
      _engine.state.status != IPTVStatus.disposed;
  @override
  bool get isMuted => _engine.state.isMuted;
  @override
  Duration get position => _engine.player.state.position;
  @override
  Duration get duration => _engine.player.state.duration;
  @override
  double get volume => _engine.state.volume;
  @override
  int get bufferHealth => _engine.state.bufferHealth;
  @override
  bool get hasError => _engine.state.hasError;
  @override
  String? get errorMessage => _engine.state.errorMessage;

  @override
  Future<void> play() => _engine.play();
  @override
  Future<void> pause() => _engine.pause();
  @override
  Future<void> setVolume(double v) => _engine.setVolume(v);
  @override
  Future<void> setMuted(bool m) => _engine.setMuted(m);
  @override
  Future<void> retry() => _engine.reconnect();

  @override
  void addListener(void Function() l) => _engine.addListener(l);
  @override
  void removeListener(void Function() l) => _engine.removeListener(l);
  @override
  void dispose() {} // Engine is managed externally
}

// ── VideoState (shared mutable state for WebView player) ─────────────────

class VideoState {
  bool isPlaying = false;
  bool isBuffering = false;
  bool isMuted = false;
  bool isLoading = true;
  bool hasError = false;
  bool stallDetected = false;
  String? errorMessage;
  double volume = 1.0;
  int bufferHealth = 100;
  int serverIndex = 0;
  int totalServers = 0;
  String? channelId;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  final List<VoidCallback> _listeners = [];
  final StreamController<VideoStateChange> _changes =
      StreamController<VideoStateChange>.broadcast();

  Stream<VideoStateChange> get stateChanges => _changes.stream;

  void update({
    bool? playing,
    bool? buffering,
    bool? muted,
    bool? loading,
    bool? error,
    String? errorMsg,
    bool? stalled,
    int? bufHealth,
    int? servIndex,
    int? totalServ,
    String? chanId,
  }) {
    final Map<String, dynamic> diff = {};
    void chk<T>(String k, T? val, T cur, void Function(T) set) {
      if (val != null && val != cur) {
        diff[k] = val;
        set(val);
      }
    }

    chk('isPlaying', playing, isPlaying, (v) => isPlaying = v);
    chk('isBuffering', buffering, isBuffering, (v) => isBuffering = v);
    chk('isMuted', muted, isMuted, (v) => isMuted = v);
    chk('isLoading', loading, isLoading, (v) => isLoading = v);
    chk('hasError', error, hasError, (v) => hasError = v);
    chk('stallDetected', stalled, stallDetected, (v) => stallDetected = v);
    if (errorMsg != null) {
      diff['errorMessage'] = errorMsg;
      errorMessage = errorMsg;
    }
    if (bufHealth != null && bufHealth != bufferHealth) {
      diff['bufferHealth'] = bufHealth;
      bufferHealth = bufHealth;
    }
    if (servIndex != null) serverIndex = servIndex;
    if (totalServ != null) totalServers = totalServ;
    if (chanId != null) channelId = chanId;

    if (diff.isNotEmpty) _changes.add(VideoStateChange(diff));
    _notify();
  }

  void reset() => update(
        playing: false,
        buffering: false,
        loading: true,
        error: false,
        errorMsg: null,
        stalled: false,
        bufHealth: 100,
      );

  void _notify() {
    for (final l in List.of(_listeners)) {
      try {
        l();
      } catch (e) {
        debugPrint('⚠️ VideoState listener: $e');
      }
    }
  }

  void addListener(VoidCallback l) {
    if (!_listeners.contains(l)) _listeners.add(l);
  }

  void removeListener(VoidCallback l) => _listeners.remove(l);

  void dispose() {
    _listeners.clear();
    _changes.close();
  }
}

class VideoStateChange {
  final Map<String, dynamic> changes;
  final DateTime timestamp;
  VideoStateChange(this.changes) : timestamp = DateTime.now();
  bool hasChanged(String k) => changes.containsKey(k);
  T? getValue<T>(String k) => changes[k] as T?;
}

// ── WebView Adapter ───────────────────────────────────────────────────────

class _WebControllerAdapter implements UnifiedVideoController {
  final WebViewController _wvc;
  final VideoState _state;
  Timer? _syncTimer;
  bool _disposed = false;

  _WebControllerAdapter(this._wvc, this._state) {
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed) return;
      _js('if(window.FlutterBridge)window.FlutterBridge.sendStateUpdate()');
    });
  }

  @override
  bool get isPlaying => _state.isPlaying;
  @override
  bool get isBuffering => _state.isBuffering;
  @override
  bool get isInitialized => !_state.isLoading;
  @override
  bool get isMuted => _state.isMuted;
  @override
  Duration get position => _state.position;
  @override
  Duration get duration => _state.duration;
  @override
  double get volume => _state.volume;
  @override
  int get bufferHealth => _state.bufferHealth;
  @override
  bool get hasError => _state.hasError;
  @override
  String? get errorMessage => _state.errorMessage;

  @override
  Future<void> play() => _js('window.play()');
  @override
  Future<void> pause() => _js('window.pause()');
  @override
  Future<void> setVolume(double v) => _js('window.setVolume(${v.clamp(0, 1)})');
  @override
  Future<void> setMuted(bool m) => _js(m ? 'window.mute()' : 'window.unmute()');
  @override
  Future<void> retry() => _js('window.retryCurrentServer()');

  Future<void> _js(String script) async {
    if (_disposed) return;
    try {
      await _wvc.runJavaScript('(function(){try{$script}catch(e){}})()');
    } catch (e) {
      debugPrint('⚠️ WebAdapter JS: $e');
    }
  }

  @override
  void addListener(void Function() l) => _state.addListener(l);
  @override
  void removeListener(void Function() l) => _state.removeListener(l);

  @override
  void dispose() {
    _disposed = true;
    _syncTimer?.cancel();
  }
}