import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import '../models/radio.dart' as model;

/// Enhanced manager for handling live audio streams with advanced features
/// Supports multiple formats (m3u8, aac, mp3, sc) with automatic error recovery
class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal() {
    _setupErrorHandling();
  }

  final AudioPlayer _player = AudioPlayer();
  model.Radio? _currentStation;
  bool _isInit = false;

  // Reconnection state
  int _currentUrlIndex = 0;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  Timer? _reconnectionTimer;
  bool _isReconnecting = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Streams for UI consumption
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  model.Radio? get currentStation => _currentStation;
  bool get isPlaying => _player.playing;
  bool get isReconnecting => _isReconnecting;

  /// Initialize background audio support
  Future<void> initialize() async {
    if (_isInit) return;
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.pivote.radio_playback',
        androidNotificationChannelName: 'Radio Playback',
        androidNotificationOngoing: true,
      );
      _isInit = true;
      debugPrint('✅ AudioManager initialized with background support');
    } catch (e) {
      debugPrint('❌ Error initializing JustAudioBackground: $e');
    }
  }

  /// Setup error handling and automatic recovery
  void _setupErrorHandling() {
    _playerStateSubscription = _player.playerStateStream.listen(
      (state) {
        // Detect errors and trigger recovery
        if (state.processingState == ProcessingState.idle &&
            _currentStation != null &&
            !_isReconnecting &&
            _player.playing == false) {
          // Stream might have stopped unexpectedly
          debugPrint('⚠️ Stream stopped unexpectedly, attempting recovery...');
          _attemptReconnection();
        }
      },
      onError: (error) {
        debugPrint('❌ Player stream error: $error');
        _attemptReconnection();
      },
    );
  }

  /// Play a specific radio station with multi-URL fallback
  Future<void> play(model.Radio station) async {
    if (_currentStation?.id == station.id && _player.playing) return;

    // Cancel any ongoing reconnection
    _cancelReconnection();

    _currentStation = station;
    _currentUrlIndex = 0;
    _retryCount = 0;
    notifyListeners();

    await _playWithUrl(station, 0);
  }

  /// Internal method to play with specific URL index
  Future<void> _playWithUrl(model.Radio station, int urlIndex) async {
    if (urlIndex >= station.streamUrl.length) {
      debugPrint('❌ All stream URLs failed for ${station.name}');
      _currentStation = null;
      notifyListeners();
      return;
    }

    try {
      final url = station.streamUrl[urlIndex];
      if (url.isEmpty) {
        throw Exception('Empty stream URL at index $urlIndex');
      }

      debugPrint(
          '🎧 Attempting to play: ${station.name} from $url (URL ${urlIndex + 1}/${station.streamUrl.length})');

      // Configure player for live streaming
      await _configurePlayerForLiveStream();

      // Create AudioSource with background info
      final source = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: station.id,
          title: station.name,
          album: 'Pivote Radio',
          artist: station.frequency,
          artUri: Uri.tryParse(station.logoUrl),
        ),
      );

      // Set audio source with timeout
      await _player.setAudioSource(source).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Stream connection timeout');
        },
      );

      // Start playback
      await _player.play();
      _retryCount = 0; // Reset retry count on success
      debugPrint('✅ Now playing: ${station.name}');
      notifyListeners();
    } catch (e) {
      debugPrint(
          '❌ Error playing station ${station.name} with URL $urlIndex: $e');

      // Try next URL if available
      if (urlIndex + 1 < station.streamUrl.length) {
        debugPrint('🔄 Trying next URL...');
        _currentUrlIndex = urlIndex + 1;
        await _playWithUrl(station, _currentUrlIndex);
      } else {
        // All URLs failed, attempt reconnection with first URL
        _attemptReconnection();
      }
    }
  }

  /// Configure player settings optimized for live streaming
  Future<void> _configurePlayerForLiveStream() async {
    try {
      // Set audio session for media playback
      await _player.setVolume(1.0);
      // Note: just_audio handles buffering automatically for live streams
      // Additional configuration can be added here if needed
    } catch (e) {
      debugPrint('⚠️ Error configuring player: $e');
    }
  }

  /// Attempt automatic reconnection with exponential backoff
  void _attemptReconnection() {
    if (_currentStation == null || _isReconnecting) return;
    if (_retryCount >= _maxRetries) {
      debugPrint('❌ Max reconnection attempts reached');
      _currentStation = null;
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _isReconnecting = true;
    notifyListeners();

    // Calculate delay with exponential backoff
    final delay = _initialRetryDelay * (1 << _retryCount); // 2^retryCount
    _retryCount++;

    debugPrint(
        '🔄 Reconnection attempt $_retryCount/$_maxRetries in ${delay.inSeconds}s...');

    _reconnectionTimer = Timer(delay, () async {
      if (_currentStation != null) {
        debugPrint('🔄 Attempting to reconnect to ${_currentStation!.name}...');
        try {
          await _playWithUrl(_currentStation!, _currentUrlIndex);
          _isReconnecting = false;
          notifyListeners();
        } catch (e) {
          debugPrint('❌ Reconnection failed: $e');
          _attemptReconnection(); // Try again
        }
      }
    });
  }

  /// Cancel ongoing reconnection attempts
  void _cancelReconnection() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    _isReconnecting = false;
    _retryCount = 0;
  }

  /// Stop playback and cleanup
  Future<void> stop() async {
    _cancelReconnection();
    await _player.stop();
    _currentStation = null;
    _currentUrlIndex = 0;
    _retryCount = 0;
    notifyListeners();
  }

  /// Pause playback
  Future<void> pause() async {
    _cancelReconnection();
    await _player.pause();
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error resuming playback: $e');
      // If resume fails, attempt reconnection
      _attemptReconnection();
    }
  }

  @override
  void dispose() {
    _cancelReconnection();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}
