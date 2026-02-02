import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import '../models/radio.dart' as model;

/// Enhanced manager for handling live audio streams with advanced features
/// Supports multiple formats (m3u8, aac, mp3, streamtheworld) with automatic error recovery
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
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  Timer? _reconnectionTimer;
  bool _isReconnecting = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;

  // Streams for UI consumption
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  model.Radio? get currentStation => _currentStation;
  bool get isPlaying => _player.playing;
  bool get isReconnecting => _isReconnecting;

  /// Initialize background audio support and audio session
  Future<void> initialize() async {
    if (_isInit) return;
    try {
      // 1. Initialize Background Service
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.pivote.radio_playback',
        androidNotificationChannelName: 'Radio Playback',
        androidNotificationOngoing: true,
        androidResumeOnClick: true,
      );

      // 2. Configure Audio Session (Handling calls, other apps, etc.)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle audio focus loss
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              resume();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });

      // Handle unplugging headphones
      session.becomingNoisyEventStream.listen((_) => pause());

      _isInit = true;
      debugPrint('✅ AudioManager initialized with background and session support');
    } catch (e) {
      debugPrint('❌ Error initializing JustAudio: $e');
    }
  }

  /// Setup error handling and automatic recovery
  void _setupErrorHandling() {
    // Monitor player state for unexpected stops
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

    // Monitor playback events for errors
    _playbackEventSubscription = _player.playbackEventStream.listen(
      (event) {
        // Check for errors in playback event
        if (event.processingState == ProcessingState.idle && 
            _currentStation != null && 
            !_isReconnecting) {
          debugPrint('⚠️ Playback stopped unexpectedly');
        }
      },
      onError: (error) {
        debugPrint('❌ Playback event error: $error');
        _attemptReconnection();
      },
    );
  }

  /// Play a specific radio station with multi-URL fallback
  Future<void> play(model.Radio station) async {
    if (_currentStation?.id == station.id && _player.playing) {
      debugPrint('🔵 Station already playing: ${station.name}');
      return;
    }

    // Cancel any ongoing reconnection
    _cancelReconnection();

    // Stop current playback first
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('⚠️ Error stopping previous playback: $e');
    }

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

      debugPrint('🎧 Attempting to play: ${station.name}');
      debugPrint('   URL ${urlIndex + 1}/${station.streamUrl.length}: $url');

      // Headers to avoid being blocked by servers
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Icy-MetaData': '1', // Request stream metadata
      };

      // Detect stream type and create appropriate source
      AudioSource source;
      
      if (url.contains('.m3u8') || url.contains('m3u8')) {
        // HLS stream
        debugPrint('   Format: HLS (m3u8)');
        source = HlsAudioSource(
          Uri.parse(url),
          headers: headers,
          tag: MediaItem(
            id: station.id,
            title: station.name,
            album: 'Pivote Radio',
            artist: station.frequency,
            artUri: Uri.tryParse(station.logoUrl),
          ),
        );
      } else if (url.contains('streamtheworld') || url.contains('.pls')) {
        // StreamTheWorld or PLS streams - often need special handling
        debugPrint('   Format: StreamTheWorld/PLS');
        source = AudioSource.uri(
          Uri.parse(url),
          headers: headers,
          tag: MediaItem(
            id: station.id,
            title: station.name,
            album: 'Pivote Radio',
            artist: station.frequency,
            artUri: Uri.tryParse(station.logoUrl),
          ),
        );
      } else {
        // Standard MP3/AAC stream
        debugPrint('   Format: Standard (MP3/AAC)');
        source = AudioSource.uri(
          Uri.parse(url),
          headers: headers,
          tag: MediaItem(
            id: station.id,
            title: station.name,
            album: 'Pivote Radio',
            artist: station.frequency,
            artUri: Uri.tryParse(station.logoUrl),
          ),
        );
      }

      // Set audio source with timeout
      await _player.setAudioSource(source, preload: false).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('Stream connection timeout after 20s');
        },
      );

      // Configure for live streaming
      await _player.setVolume(1.0);

      // Start playback
      await _player.play();
      
      _retryCount = 0; // Reset retry count on success
      _currentUrlIndex = urlIndex; // Save successful URL index
      
      debugPrint('✅ Successfully playing: ${station.name}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error playing ${station.name} with URL $urlIndex: $e');

      // Try next URL if available
      if (urlIndex + 1 < station.streamUrl.length) {
        debugPrint('🔄 Trying next URL (${urlIndex + 2}/${station.streamUrl.length})...');
        await Future.delayed(const Duration(milliseconds: 500));
        await _playWithUrl(station, urlIndex + 1);
      } else {
        // All URLs failed, attempt reconnection with first URL
        debugPrint('⚠️ All URLs failed, starting reconnection attempts...');
        _currentUrlIndex = 0;
        _attemptReconnection();
      }
    }
  }

  /// Attempt automatic reconnection with exponential backoff
  void _attemptReconnection() {
    if (_currentStation == null || _isReconnecting) return;
    
    if (_retryCount >= _maxRetries) {
      debugPrint('❌ Max reconnection attempts reached ($_maxRetries)');
      _currentStation = null;
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _isReconnecting = true;
    notifyListeners();

    // Calculate delay with exponential backoff: 2s, 4s, 8s
    final delay = _initialRetryDelay * (1 << _retryCount);
    _retryCount++;

    debugPrint('🔄 Reconnection attempt $_retryCount/$_maxRetries in ${delay.inSeconds}s...');

    _reconnectionTimer = Timer(delay, () async {
      if (_currentStation != null) {
        debugPrint('🔄 Reconnecting to ${_currentStation!.name}...');
        try {
          // Try current URL index first, then fallback to others
          await _playWithUrl(_currentStation!, _currentUrlIndex);
          _isReconnecting = false;
          notifyListeners();
        } catch (e) {
          debugPrint('❌ Reconnection failed: $e');
          _attemptReconnection(); // Try again
        }
      } else {
        _isReconnecting = false;
        notifyListeners();
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

  /// Stop playback and cleanup - CRITICAL FOR YOUR REQUEST
  /// This MUST be called when exiting the player screen
  Future<void> stop() async {
    debugPrint('🛑 Stopping playback...');
    _cancelReconnection();
    
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      debugPrint('⚠️ Error stopping player: $e');
    }
    
    _currentStation = null;
    _currentUrlIndex = 0;
    _retryCount = 0;
    notifyListeners();
    debugPrint('✅ Playback stopped and cleaned up');
  }

  /// Pause playback
  Future<void> pause() async {
    _cancelReconnection();
    try {
      await _player.pause();
      debugPrint('⏸️ Playback paused');
    } catch (e) {
      debugPrint('❌ Error pausing: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.play();
      debugPrint('▶️ Playback resumed');
    } catch (e) {
      debugPrint('❌ Error resuming playback: $e');
      // If resume fails, attempt reconnection
      _attemptReconnection();
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing AudioManager');
    _cancelReconnection();
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}