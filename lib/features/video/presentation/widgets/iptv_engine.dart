import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// ════════════════════════════════════════════════════════════════════════════
// IPTV ENGINE v2.0 — libmpv-powered professional IPTV engine
// ════════════════════════════════════════════════════════════════════════════
//
// Architecture:
//   IPTVEngine wraps media_kit's Player (libmpv backend) with:
//   - Aggressive live-TV buffer tuning (demuxer 32 MB, cache 10 s)
//   - Hardware decoding (hwdec=auto-copy, vo=gpu-next)
//   - Position-based stall watchdog with exponential-backoff reconnect
//   - ClearKey DRM via mpv clearkeys property
//   - Real-time buffer health (0–100 %)
//   - Clean state machine (idle→connecting→buffering→playing→stalled→error)
//

// ── Configuration ────────────────────────────────────────────────────────────

class IPTVConfig {
  IPTVConfig._();

  // Buffer
  static const int demuxerMaxBytes = 32 * 1024 * 1024; // 32 MB
  static const int demuxerMaxBytesLive = 16 * 1024 * 1024; // 16 MB for live
  static const double cacheSecs = 10.0;
  static const double cacheSetsLive = 5.0;
  static const int networkBufferKb = 512;
  static const int networkTimeoutSec = 10;

  // Reconnection
  static const int maxReconnectAttempts = 8;
  static const int backoffBaseMs = 300;
  static const int backoffMaxMs = 5000;

  // Watchdog
  static const Duration watchdogInterval = Duration(seconds: 3);
  static const int stallTickThreshold = 3; // 3 × 3 s = 9 s stalled
  static const Duration gracePeriod = Duration(seconds: 15);

  // MPV properties (tuned for live IPTV)
  static const Map<String, String> mpvLiveProps = {
    'cache': 'yes',
    'cache-pause': 'no',
    'cache-pause-wait': '1',
    'demuxer-max-bytes': '$demuxerMaxBytes',
    'demuxer-max-back-bytes': '8388608', // 8 MB back buffer
    'stream-buffer-size': '${networkBufferKb}k',
    'network-timeout': '$networkTimeoutSec',
    'reconnect': 'yes',
    'reconnect-delay-max': '4',
    'hwdec': 'auto-copy',
    'vo': 'gpu-next',
    'gpu-api': 'opengl',
    'vd-lavc-threads': '0', // auto-detect CPU cores
    'ad-lavc-threads': '0',
    'video-sync': 'audio',
    'interpolation': 'no',
    'tls-verify': 'no',
    'force-seekable': 'yes',
    'audio-pitch-correction': 'no',
    'audio-stream-silence': 'no',
    'gapless-audio': 'weak',
    'initial-audio-sync': 'yes',
  };

  static const String userAgent = 'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Mobile Safari/537.36';
}

// ── State ─────────────────────────────────────────────────────────────────────

enum IPTVStatus {
  idle,
  connecting,
  buffering,
  playing,
  stalled,
  reconnecting,
  error,
  disposed,
}

class IPTVEngineState {
  final IPTVStatus status;
  final bool isPlaying;
  final bool isBuffering;
  final bool isMuted;
  final double volume;
  final int bufferHealth; // 0-100
  final int reconnectAttempt;
  final String? errorMessage;
  final DateTime updatedAt;

  const IPTVEngineState({
    this.status = IPTVStatus.idle,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.bufferHealth = 0,
    this.reconnectAttempt = 0,
    this.errorMessage,
    required this.updatedAt,
  });

  IPTVEngineState copyWith({
    IPTVStatus? status,
    bool? isPlaying,
    bool? isBuffering,
    bool? isMuted,
    double? volume,
    int? bufferHealth,
    int? reconnectAttempt,
    String? errorMessage,
  }) =>
      IPTVEngineState(
        status: status ?? this.status,
        isPlaying: isPlaying ?? this.isPlaying,
        isBuffering: isBuffering ?? this.isBuffering,
        isMuted: isMuted ?? this.isMuted,
        volume: volume ?? this.volume,
        bufferHealth: bufferHealth ?? this.bufferHealth,
        reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
        errorMessage: errorMessage ?? this.errorMessage,
        updatedAt: DateTime.now(),
      );

  bool get isLoading =>
      status == IPTVStatus.connecting ||
      status == IPTVStatus.buffering ||
      status == IPTVStatus.reconnecting;

  bool get hasError => status == IPTVStatus.error;
}

// ── Engine ────────────────────────────────────────────────────────────────────

class IPTVEngine extends ChangeNotifier {
  // ── media_kit objects ──
  late final Player _player;
  late final VideoController videoController;

  // ── state ──
  IPTVEngineState _state = IPTVEngineState(updatedAt: DateTime.now());
  IPTVEngineState get state => _state;

  /// Public access for controllers (position, duration, etc.)
  Player get player => _player;

  // ── internal ──
  String? _currentUrl;
  String? _k1;
  String? _k2;
  bool _disposed = false;
  int _reconnectCount = 0;
  int _stallTicks = 0;
  DateTime? _playbackStart;
  double _lastPosition = 0;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _bufferSub;
  Timer? _watchdog;

  // ── constructor ──────────────────────────────────────────────────────────

  IPTVEngine() {
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024,
        logLevel: MPVLogLevel.warn,
        title: 'Pivote IPTV',
      ),
    );

    videoController = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
        androidAttachSurfaceAfterVideoParameters: false,
      ),
    );

    _applyMpvProperties();
    _attachStreams();
  }

  // ── MPV tuning ────────────────────────────────────────────────────────────

  Future<void> _applyMpvProperties() async {
    if (_player.platform is! NativePlayer) return;
    final native = _player.platform as NativePlayer;

    for (final entry in IPTVConfig.mpvLiveProps.entries) {
      try {
        await native.setProperty(entry.key, entry.value);
      } catch (e) {
        debugPrint('⚠️ MPV prop ${entry.key}: $e');
      }
    }

    // User-Agent for CDN authentication
    try {
      await native.setProperty(
        'user-agent',
        IPTVConfig.userAgent,
      );
    } catch (_) {}
  }

  // ── Stream subscriptions ─────────────────────────────────────────────────

  void _attachStreams() {
    _playingSub = _player.stream.playing.listen(_onPlaying);
    _bufferingSub = _player.stream.buffering.listen(_onBuffering);
    _errorSub = _player.stream.error.listen(_onError);
    _bufferSub = _player.stream.buffer.listen(_onBuffer);
  }

  void _onPlaying(bool playing) {
    if (_disposed) return;
    if (playing) {
      _playbackStart ??= DateTime.now();
      _reconnectCount = 0;
      _stallTicks = 0;
    }
    _emit(_state.copyWith(
      isPlaying: playing,
      status: playing ? IPTVStatus.playing : IPTVStatus.buffering,
    ));
  }

  void _onBuffering(bool buffering) {
    if (_disposed) return;
    if (buffering && _state.status == IPTVStatus.playing) {
      _emit(_state.copyWith(
        isBuffering: true,
        status: IPTVStatus.buffering,
      ));
    } else if (!buffering && _state.isBuffering) {
      _emit(_state.copyWith(
        isBuffering: false,
        status: IPTVStatus.playing,
      ));
    }
  }

  void _onError(String error) {
    if (_disposed) return;
    debugPrint('❌ libmpv error: $error');
    _attemptReconnect();
  }

  void _onBuffer(Duration buffered) {
    if (_disposed) return;
    // Buffer health: seconds buffered / target cache secs → 0-100 %
    final health =
        ((buffered.inMilliseconds / 1000.0) / IPTVConfig.cacheSecs * 100)
            .clamp(0.0, 100.0)
            .toInt();
    _emit(_state.copyWith(bufferHealth: health));
  }

  // ── Watchdog ──────────────────────────────────────────────────────────────

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(IPTVConfig.watchdogInterval, _watchdogTick);
  }

  void _watchdogTick(Timer _) {
    if (_disposed || _currentUrl == null) return;

    // Grace period after first play
    if (_playbackStart != null) {
      if (DateTime.now().difference(_playbackStart!) < IPTVConfig.gracePeriod) {
        return;
      }
    }

    final pos = _player.state.position.inMilliseconds / 1000.0;

    if (_state.isPlaying && !_state.isBuffering) {
      if (pos == _lastPosition) {
        _stallTicks++;
        debugPrint(
            '⚠️ Stall tick $_stallTicks/${IPTVConfig.stallTickThreshold}');
        if (_stallTicks >= IPTVConfig.stallTickThreshold) {
          _stallTicks = 0;
          debugPrint('🔄 Watchdog: stall detected → reconnecting');
          _attemptReconnect();
        }
      } else {
        _stallTicks = 0;
      }
      _lastPosition = pos;
    }
  }

  // ── Reconnection ──────────────────────────────────────────────────────────

  Future<void> _attemptReconnect() async {
    if (_disposed || _currentUrl == null) return;
    if (_reconnectCount >= IPTVConfig.maxReconnectAttempts) {
      _emit(_state.copyWith(
        status: IPTVStatus.error,
        errorMessage: 'Máximo de reconexiones alcanzado',
      ));
      return;
    }

    _reconnectCount++;
    _emit(_state.copyWith(
      status: IPTVStatus.reconnecting,
      reconnectAttempt: _reconnectCount,
    ));

    final delayMs = (_backoff(_reconnectCount)).clamp(
      IPTVConfig.backoffBaseMs,
      IPTVConfig.backoffMaxMs,
    );
    debugPrint('🔄 Reconnect #$_reconnectCount in ${delayMs}ms');

    await Future.delayed(Duration(milliseconds: delayMs));
    if (!_disposed) {
      await _loadInternal(_currentUrl!, _k1, _k2);
    }
  }

  int _backoff(int attempt) =>
      (IPTVConfig.backoffBaseMs * (1 << (attempt - 1))).clamp(
        IPTVConfig.backoffBaseMs,
        IPTVConfig.backoffMaxMs,
      );

  // ── Public API ────────────────────────────────────────────────────────────

  /// Load a new stream URL. Optionally pass [k1]/[k2] for ClearKey DRM.
  Future<void> load(String url, {String? k1, String? k2}) async {
    if (_disposed) return;

    _currentUrl = url;
    _k1 = k1;
    _k2 = k2;
    _reconnectCount = 0;
    _stallTicks = 0;
    _lastPosition = 0;
    _playbackStart = null;

    _emit(_state.copyWith(
      status: IPTVStatus.connecting,
      isPlaying: false,
      isBuffering: false,
      bufferHealth: 0,
      errorMessage: null,
    ));

    _startWatchdog();
    await _loadInternal(url, k1, k2);
  }

  Future<void> _loadInternal(String url, String? k1, String? k2) async {
    if (_disposed) return;

    try {
      await _player.stop();
    } catch (_) {}

    final headers = <String, String>{
      'User-Agent': IPTVConfig.userAgent,
    };

    // ClearKey DRM: pass as MPV clearkeys property before open
    if (k1 != null && k2 != null && k1.isNotEmpty && k2.isNotEmpty) {
      if (_player.platform is NativePlayer) {
        try {
          await (_player.platform as NativePlayer)
              .setProperty('clearkeys', '$k1:$k2');
        } catch (e) {
          debugPrint('⚠️ ClearKey property error: $e');
        }
      }
      headers['clearkeys'] = '$k1:$k2';
    }

    try {
      final media = Media(url, httpHeaders: headers);
      await _player.open(Playlist([media]), play: true);
      debugPrint('✅ IPTVEngine: stream opened → $url');
    } catch (e) {
      debugPrint('❌ IPTVEngine open error: $e');
      await _attemptReconnect();
    }
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();

  Future<void> setVolume(double v) async {
    if (_disposed) return;
    final clamped = v.clamp(0.0, 1.0);
    await _player.setVolume(clamped * 100);
    _emit(_state.copyWith(volume: clamped, isMuted: clamped == 0));
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    await _player.setVolume(muted ? 0 : _state.volume * 100);
    _emit(_state.copyWith(isMuted: muted));
  }

  /// Force immediate reconnect (used by UI retry button)
  Future<void> reconnect() async {
    _reconnectCount = 0;
    if (_currentUrl != null) {
      await _loadInternal(_currentUrl!, _k1, _k2);
    }
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  void _emit(IPTVEngineState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _watchdog?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _errorSub?.cancel();
    _bufferSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}