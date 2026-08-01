import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pivote/features/movies/data/services/embed_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── VOD Engine Configuration ──────────────────────────────────────────────────

class MovieEngineConfig {
  MovieEngineConfig._();

  // Optimizations for static VOD contents (MP4 / HLS)
  static const int demuxerMaxBytes = 128 * 1024 * 1024; // 128 MB buffer
  static const double cacheSecs = 30.0; // 30s cache
  
  static const int maxRetryAttempts = 3;
  static const int backoffBaseMs = 1000;
  static const int backoffMaxMs = 4000;

  static const Map<String, String> mpvVodProps = {
    'cache': 'yes',
    'cache-pause': 'yes',
    'cache-pause-wait': '3', 
    'cache-secs': '$cacheSecs',
    'demuxer-max-bytes': '$demuxerMaxBytes',
    'demuxer-max-back-bytes': '33554432', // 32 MB back buffer
    'hwdec': 'auto-copy',
    'vo': 'gpu-next',
    'gpu-api': 'opengl',
    'vd-lavc-threads': '0',
    'ad-lavc-threads': '0',
    'video-sync': 'audio',
    'tls-verify': 'no',
    'force-seekable': 'yes',
    'audio-pitch-correction': 'yes',
    'hls-bitrate': 'max',
    'ytdl-format': 'bestvideo+bestaudio/best',
  };

  static const String userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/124.0.0.0 Safari/537.36';
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

  /// True once the player has decoded and displayed at least one frame.
  /// Used by the UI to distinguish the initial cinematic loading screen
  /// (before first frame) from mid-playback buffering (frame stays on
  /// screen, only a small spinner is shown on top).
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
  late final Player _player;
  late final VideoController videoController;

  MovieEngineState _state = const MovieEngineState();
  MovieEngineState get state => _state;

  Player get player => _player;

  String? _currentUrl;
  bool _disposed = false;
  int _retryCount = 0;

  // Stream Subscriptions
  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _bufferSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _tracksSub;
  StreamSubscription? _trackSub;

  MovieVideoEngine() {
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: MovieEngineConfig.demuxerMaxBytes,
        logLevel: MPVLogLevel.warn,
        title: 'Pivote Movie Player',
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
    _restorePreferredSpeed();
  }

  static const String _speedPrefKey = 'movie_preferred_playback_speed';

  Future<void> _restorePreferredSpeed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_speedPrefKey);
      if (saved != null && saved != _state.playbackSpeed && !_disposed) {
        await setPlaybackSpeed(saved, persist: false);
      }
    } catch (_) {}
  }

  Future<void> _applyMpvProperties() async {
    if (_player.platform is! NativePlayer) return;
    final native = _player.platform as NativePlayer;

    for (final entry in MovieEngineConfig.mpvVodProps.entries) {
      try {
        await native.setProperty(entry.key, entry.value);
      } catch (e) {
        debugPrint('⚠️ MPV prop ${entry.key}: $e');
      }
    }

    try {
      await native.setProperty('user-agent', MovieEngineConfig.userAgent);
    } catch (_) {}
  }

  void _attachStreams() {
    _playingSub = _player.stream.playing.listen(_onPlaying);
    _bufferingSub = _player.stream.buffering.listen(_onBuffering);
    _positionSub = _player.stream.position.listen(_onPosition);
    _durationSub = _player.stream.duration.listen(_onDuration);
    _bufferSub = _player.stream.buffer.listen(_onBuffer);
    _completedSub = _player.stream.completed.listen(_onCompleted);
    _errorSub = _player.stream.error.listen(_onError);
    _tracksSub = _player.stream.tracks.listen(_onTracks);
    _trackSub = _player.stream.track.listen(_onTrack);
  }

  void _onPlaying(bool playing) {
    if (_disposed) return;
    
    MoviePlayerStatus status = _state.status;
    if (playing) {
      status = _state.isBuffering ? MoviePlayerStatus.buffering : MoviePlayerStatus.playing;
    } else {
      if (status != MoviePlayerStatus.completed && status != MoviePlayerStatus.error) {
        status = MoviePlayerStatus.paused;
      }
    }

    _emit(_state.copyWith(
      isPlaying: playing,
      status: status,
    ));
  }

  void _onBuffering(bool buffering) {
    if (_disposed) return;

    MoviePlayerStatus status = _state.status;
    if (buffering) {
      status = MoviePlayerStatus.buffering;
    } else {
      if (_state.isPlaying) {
        status = MoviePlayerStatus.playing;
      } else {
        status = MoviePlayerStatus.paused;
      }
    }

    _emit(_state.copyWith(
      isBuffering: buffering,
      status: status,
    ));
  }

  void _onPosition(Duration pos) {
    if (_disposed) return;
    _emit(_state.copyWith(position: pos));
  }

  void _onDuration(Duration dur) {
    if (_disposed) return;
    _emit(_state.copyWith(duration: dur));
  }

  void _onBuffer(Duration buf) {
    if (_disposed) return;
    _emit(_state.copyWith(buffered: buf));
  }

  void _onCompleted(bool completed) {
    if (_disposed) return;
    if (completed) {
      _emit(_state.copyWith(status: MoviePlayerStatus.completed));
    }
  }

  void _onError(String error) {
    if (_disposed) return;
    debugPrint('❌ Movie VOD Engine error: $error');
    _handlePlaybackError(error);
  }

  void _onTracks(Tracks tracks) {
    if (_disposed) return;
    _emit(_state.copyWith(tracks: tracks));
  }

  void _onTrack(Track track) {
    if (_disposed) return;
    _emit(_state.copyWith(track: track));
  }

  // ── Error & Retry Handling ────────────────────────────────────────────────

  Future<void> _handlePlaybackError(String error) async {
    // Before burning a retry on the same URL, try the next resolved stream
    // candidate (embed hosts often list several mirrors/qualities).
    if (_advanceCandidate()) {
      _retryCount = 0;
      _emit(_state.copyWith(status: MoviePlayerStatus.loading));
      if (!_disposed && _currentUrl != null) {
        await _loadInternal(_currentUrl!);
      }
      return;
    }

    if (_retryCount >= MovieEngineConfig.maxRetryAttempts) {
      _emit(_state.copyWith(
        status: MoviePlayerStatus.error,
        errorMessage: 'Error de reproducción. Verifica tu conexión.',
      ));
      return;
    }

    _retryCount++;
    _emit(_state.copyWith(
      status: MoviePlayerStatus.loading,
      retryAttempt: _retryCount,
    ));

    final delay = (MovieEngineConfig.backoffBaseMs * (1 << (_retryCount - 1)))
        .clamp(MovieEngineConfig.backoffBaseMs, MovieEngineConfig.backoffMaxMs);
    
    debugPrint('🔄 VOD Engine error retry #$_retryCount in ${delay}ms');
    await Future.delayed(Duration(milliseconds: delay));

    if (!_disposed && _currentUrl != null) {
      await _loadInternal(_currentUrl!);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Resolution produced by [EmbedResolver] for the current URL: stream
  /// candidates (fallback list) plus the HTTP headers the CDN expects.
  EmbedResolution? _resolution;
  int _candidateIndex = 0;

  Future<void> load(String url, {Duration startPosition = Duration.zero}) async {
    if (_disposed) return;

    _currentUrl = url;
    _retryCount = 0;
    _resolution = null;
    _candidateIndex = 0;

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

    // Resolve embed pages (StreamHG / StreamWish / Filemoon style) into a
    // real playable stream. Direct media URLs pass straight through.
    try {
      _resolution = await EmbedResolver.instance.resolve(url);
      debugPrint('🧩 MovieVideoEngine: $_resolution');
    } catch (e) {
      debugPrint('❌ MovieVideoEngine embed resolve failed: $e');
      if (_disposed) return;
      // If it looked like an embed and scraping failed, surface the error;
      // otherwise fall back to trying the raw URL directly.
      if (EmbedResolver.instance.looksLikeEmbed(url)) {
        _emit(_state.copyWith(
          status: MoviePlayerStatus.error,
          errorMessage: 'No se pudo obtener el video de la fuente.',
        ));
        return;
      }
    }

    if (_disposed) return;
    await _loadInternal(url, startPosition: startPosition);
  }

  /// The stream URL to actually feed the player for the current attempt.
  String _effectiveUrl(String fallback) {
    final res = _resolution;
    if (res == null || res.candidates.isEmpty) return fallback;
    return res.candidates[_candidateIndex.clamp(0, res.candidates.length - 1)];
  }

  /// Advances to the next resolved candidate. Returns true if there was one.
  bool _advanceCandidate() {
    final res = _resolution;
    if (res == null) return false;
    if (_candidateIndex + 1 >= res.candidates.length) return false;
    _candidateIndex++;
    debugPrint(
        '🧩 MovieVideoEngine: falling back to candidate #$_candidateIndex -> ${res.candidates[_candidateIndex]}');
    return true;
  }

  Future<void> _loadInternal(String url, {Duration startPosition = Duration.zero}) async {
    if (_disposed) return;

    try {
      await _player.stop();
    } catch (_) {}

    final headers = <String, String>{
      'User-Agent': MovieEngineConfig.userAgent,
      ...?_resolution?.headers,
    };

    final streamUrl = _effectiveUrl(url);

    try {
      final media = Media(streamUrl, httpHeaders: headers);
      await _player.open(Playlist([media]), play: true);
      
      if (startPosition > Duration.zero) {
        await _player.seek(startPosition);
      }
      
      debugPrint('🎬 MovieVideoEngine: opened stream -> $streamUrl');
    } catch (e) {
      debugPrint('❌ MovieVideoEngine load error: $e');
      await _handlePlaybackError(e.toString());
    }
  }

  Future<void> play() async {
    if (_disposed) return;
    await _player.play();
  }

  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    if (_disposed) return;
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    final clamped = volume.clamp(0.0, 1.0);
    await _player.setVolume(clamped * 100);
    _emit(_state.copyWith(
      volume: clamped,
      isMuted: clamped == 0.0,
    ));
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed) return;
    await _player.setVolume(muted ? 0 : _state.volume * 100);
    _emit(_state.copyWith(isMuted: muted));
  }

  Future<void> setPlaybackSpeed(double speed, {bool persist = true}) async {
    if (_disposed) return;
    await _player.setRate(speed);
    _emit(_state.copyWith(playbackSpeed: speed));

    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_speedPrefKey, speed);
      } catch (_) {}
    }
  }

  Future<void> setSubtitleTrack(SubtitleTrack track) async {
    if (_disposed) return;
    await _player.setSubtitleTrack(track);
  }

  Future<void> setAudioTrack(AudioTrack track) async {
    if (_disposed) return;
    await _player.setAudioTrack(track);
  }

  Future<void> addSubtitleSource(String url) async {
    if (_disposed) return;
    // media_kit supports adding external subtitles via native properties or standard loading.
    // For general usage, let's keep it simple or allow setting it via uri if supported.
  }

  /// Immediately stops playback (used before exiting the player screen)
  Future<void> stop() async {
    if (_disposed) return;
    try {
      await _player.stop();
    } catch (_) {}
    _emit(_state.copyWith(
      status: MoviePlayerStatus.idle,
      isPlaying: false,
      isBuffering: false,
    ));
  }

  Future<void> retry() async {
    if (_disposed || _currentUrl == null) return;
    _retryCount = 0;
    // Manual retry: drop the cached resolution so we re-scrape the embed and
    // get fresh (possibly re-tokenized) stream URLs.
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
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _bufferSub?.cancel();
    _completedSub?.cancel();
    _errorSub?.cancel();
    _tracksSub?.cancel();
    _trackSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
