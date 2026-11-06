import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pivote/features/movies/data/services/embed_resolver.dart';
import 'package:pivote/features/video/presentation/widgets/exo_player_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── VOD Engine Configuration ──────────────────────────────────────────────────

class MovieEngineConfig {
  MovieEngineConfig._();

  static const int maxRetryAttempts = 3;
  static const int backoffBaseMs = 1000;
  static const int backoffMaxMs = 4000;
  static const double cacheSecs = 30.0;

  static const String userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';
}

// ── Track Models compatible with UI ──────────────────────────────────────────

class SubtitleTrack {
  final String id;
  final String? title;
  final String? language;
  final PlayerTrack? nativeTrack;

  const SubtitleTrack({
    required this.id,
    this.title,
    this.language,
    this.nativeTrack,
  });

  factory SubtitleTrack.no() => const SubtitleTrack(id: 'no', title: 'Desactivado');
  factory SubtitleTrack.auto() => const SubtitleTrack(id: 'auto', title: 'Automático');

  static SubtitleTrack fromPlayerTrack(PlayerTrack t) {
    return SubtitleTrack(
      id: t.id,
      title: t.label.isNotEmpty ? t.label : (t.language.isNotEmpty ? t.language.toUpperCase() : null),
      language: t.language.isNotEmpty ? t.language : null,
      nativeTrack: t,
    );
  }
}

class AudioTrack {
  final String id;
  final String? title;
  final String? language;
  final PlayerTrack? nativeTrack;

  const AudioTrack({
    required this.id,
    this.title,
    this.language,
    this.nativeTrack,
  });

  factory AudioTrack.auto() => const AudioTrack(id: 'auto', title: 'Automático');

  static AudioTrack fromPlayerTrack(PlayerTrack t) {
    return AudioTrack(
      id: t.id,
      title: t.label.isNotEmpty ? t.label : (t.language.isNotEmpty ? t.language.toUpperCase() : null),
      language: t.language.isNotEmpty ? t.language : null,
      nativeTrack: t,
    );
  }
}

class Tracks {
  final List<SubtitleTrack> subtitle;
  final List<AudioTrack> audio;

  const Tracks({
    this.subtitle = const [],
    this.audio = const [],
  });
}

class Track {
  final SubtitleTrack subtitle;
  final AudioTrack audio;

  const Track({
    this.subtitle = const SubtitleTrack(id: 'no', title: 'Desactivado'),
    this.audio = const AudioTrack(id: 'auto', title: 'Automático'),
  });

  Track copyWith({
    SubtitleTrack? subtitle,
    AudioTrack? audio,
  }) {
    return Track(
      subtitle: subtitle ?? this.subtitle,
      audio: audio ?? this.audio,
    );
  }
}

// ── State Machine ─────────────────────────────────────────────────────────────

enum MoviePlayerStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  error,
  completed,
}

class MovieEngineState {
  final MoviePlayerStatus status;
  final bool isPlaying;
  final bool isBuffering;
  final bool isMuted;
  final double volume; // 0.0 to 1.0
  final double playbackSpeed; // 0.5 to 2.0
  final Duration position;
  final Duration duration;
  final Duration buffered;
  final String? errorMessage;
  final int retryAttempt;
  final Tracks tracks;
  final Track track;

  const MovieEngineState({
    this.status = MoviePlayerStatus.idle,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = Duration.zero,
    this.errorMessage,
    this.retryAttempt = 0,
    this.tracks = const Tracks(),
    this.track = const Track(),
  });

  MovieEngineState copyWith({
    MoviePlayerStatus? status,
    bool? isPlaying,
    bool? isBuffering,
    bool? isMuted,
    double? volume,
    double? playbackSpeed,
    Duration? position,
    Duration? duration,
    Duration? buffered,
    String? errorMessage,
    int? retryAttempt,
    Tracks? tracks,
    Track? track,
  }) {
    return MovieEngineState(
      status: status ?? this.status,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      errorMessage: errorMessage ?? this.errorMessage,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      tracks: tracks ?? this.tracks,
      track: track ?? this.track,
    );
  }

  bool get hasStartedPlayback =>
      status == MoviePlayerStatus.playing ||
      status == MoviePlayerStatus.paused ||
      status == MoviePlayerStatus.completed;

  bool get isLoading =>
      status == MoviePlayerStatus.loading ||
      status == MoviePlayerStatus.buffering;

  bool get hasError => status == MoviePlayerStatus.error;
}

// ── Engine ────────────────────────────────────────────────────────────────────

class MovieVideoEngine extends ChangeNotifier {
  late final PivotePlayerController _controller;
  PivotePlayerController get controller => _controller;

  MovieEngineState _state = const MovieEngineState();
  MovieEngineState get state => _state;

  String? _currentUrl;
  bool _disposed = false;
  int _retryCount = 0;
  int get retryCount => _retryCount;
  Duration _startPosition = Duration.zero;

  static const String _speedPrefKey = 'pivote_movie_playback_speed';

  MovieVideoEngine() {
    _controller = PivotePlayerController();
    _controller.addListener(_onControllerState);
    _restoreSpeed();
  }

  Future<void> _restoreSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSpeed = prefs.getDouble(_speedPrefKey);
      if (savedSpeed != null && savedSpeed > 0) {
        await _controller.setPlaybackSpeed(savedSpeed);
        _emit(_state.copyWith(playbackSpeed: savedSpeed));
      }
    } catch (_) {}
  }

  void _onControllerState() {
    if (_disposed) return;

    MoviePlayerStatus newStatus = _state.status;

    if (_controller.hasError) {
      newStatus = MoviePlayerStatus.error;
    } else if (_controller.isBuffering) {
      newStatus = MoviePlayerStatus.buffering;
    } else if (_controller.isPlaying || _controller.firstFrameRendered) {
      newStatus = MoviePlayerStatus.playing;
    } else if (_controller.isReady && !_controller.isPlaying) {
      newStatus = MoviePlayerStatus.paused;
    }

    // Convertir tracks de ExoPlayer a modelos de Movie UI
    final subTracks = _controller.textTracks.map(SubtitleTrack.fromPlayerTrack).toList();
    final audTracks = _controller.audioTracks.map(AudioTrack.fromPlayerTrack).toList();

    final currentSub = _controller.selectedSubtitleTrack != null
        ? SubtitleTrack.fromPlayerTrack(_controller.selectedSubtitleTrack!)
        : SubtitleTrack.no();

    final currentAud = _controller.selectedAudioTrack != null
        ? AudioTrack.fromPlayerTrack(_controller.selectedAudioTrack!)
        : (audTracks.isNotEmpty ? audTracks.first : AudioTrack.auto());

    _emit(_state.copyWith(
      status: newStatus,
      isPlaying: _controller.isPlaying,
      isBuffering: _controller.isBuffering,
      position: _controller.position,
      duration: _controller.duration,
      buffered: _controller.buffered,
      volume: _controller.volume,
      isMuted: _controller.isMuted,
      playbackSpeed: _controller.playbackSpeed,
      errorMessage: _controller.errorMessage,
      tracks: Tracks(subtitle: subTracks, audio: audTracks),
      track: Track(subtitle: currentSub, audio: currentAud),
    ));

    // Si teníamos una posición inicial pendiente de seek
    if (_startPosition > Duration.zero && _controller.isReady && _controller.position < const Duration(seconds: 1)) {
      final pos = _startPosition;
      _startPosition = Duration.zero;
      _controller.seekTo(pos);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  EmbedResolution? _resolution;
  int _candidateIndex = 0;

  Future<void> load(String url, {Duration startPosition = Duration.zero}) async {
    if (_disposed) return;

    _currentUrl = url;
    _retryCount = 0;
    _resolution = null;
    _candidateIndex = 0;
    _startPosition = startPosition;

    _emit(_state.copyWith(
      status: MoviePlayerStatus.loading,
      isPlaying: false,
      isBuffering: false,
      position: startPosition,
      duration: Duration.zero,
      buffered: Duration.zero,
      errorMessage: null,
      retryAttempt: 0,
    ));

    try {
      _resolution = await EmbedResolver.instance.resolve(url);
    } catch (e) {
      debugPrint('❌ MovieVideoEngine embed resolve failed: $e');
      if (_disposed) return;
    }

    if (_disposed) return;

    final targetUrl = _pickStreamUrl(url);
    await _loadInternal(targetUrl);
  }

  String _pickStreamUrl(String fallbackUrl) {
    final r = _resolution;
    if (r == null) return fallbackUrl;
    if (r.candidates.isNotEmpty) {
      final index = _candidateIndex.clamp(0, r.candidates.length - 1);
      return r.candidates[index];
    }
    return r.primary.isNotEmpty ? r.primary : fallbackUrl;
  }

  Future<void> _loadInternal(String streamUrl) async {
    if (_disposed) return;

    final headers = <String, String>{
      'User-Agent': MovieEngineConfig.userAgent,
    };

    if (_resolution != null) {
      headers.addAll(_resolution!.headers);
    }

    await _controller.prepare(
      url: streamUrl,
      headers: headers,
    );
  }

  Future<void> play() async {
    if (_disposed) return;
    await _controller.play();
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _controller.pause();
  }

  Future<void> togglePlayPause() async {
    if (_disposed) return;
    await _controller.togglePlayPause();
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _controller.seekTo(position);
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await _controller.setVolume(volume);
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    if (muted) {
      await _controller.setVolume(0.0);
    } else {
      await _controller.setVolume(_state.volume > 0 ? _state.volume : 1.0);
    }
  }

  Future<void> setPlaybackSpeed(double speed, {bool persist = true}) async {
    if (_disposed) return;
    await _controller.setPlaybackSpeed(speed);
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_speedPrefKey, speed);
      } catch (_) {}
    }
  }

  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    if (_disposed) return;
    if (track.id == 'no') {
      await _controller.selectSubtitleTrack(null);
    } else if (track.nativeTrack != null) {
      await _controller.selectSubtitleTrack(track.nativeTrack);
    }
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    if (_disposed || track.nativeTrack == null) return;
    await _controller.selectAudioTrack(track.nativeTrack!);
  }

  Future<void> stop() async {
    if (_disposed) return;
    await _controller.pause();
    _emit(_state.copyWith(
      status: MoviePlayerStatus.idle,
      isPlaying: false,
      isBuffering: false,
    ));
  }

  Future<void> retry() async {
    if (_disposed || _currentUrl == null) return;
    _retryCount = 0;
    EmbedResolver.instance.clearCache();
    await load(_currentUrl!, startPosition: _state.position);
  }

  void _emit(MovieEngineState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_onControllerState);
    _controller.dispose();
    super.dispose();
  }
}
