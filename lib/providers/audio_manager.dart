import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import '../models/radio.dart' as model;

/// Robust AudioManager for handling radio streams
/// Implements "Nuclear Fix" strategy for maximum compatibility
class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  model.Radio? _currentStation;
  bool _isInit = false;

  // State
  bool _isReconnecting = false;
  bool _isPlaying = false;
  bool _isLoading = false;
  int _retryCount = 0;
  Timer? _reconnectionTimer;

  // Constants
  static const int _maxRetries = 5;

  // Public Getters
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  model.Radio? get currentStation => _currentStation;
  bool get isPlaying => _isPlaying;
  bool get isReconnecting => _isReconnecting;
  bool get isLoading => _isLoading;

  /// Initialize Audio Service & Session
  Future<void> initialize() async {
    if (_isInit) return;

    try {
      // 1. Setup JustAudioBackground
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.pivote.radio_playback',
        androidNotificationChannelName: 'Radio Playback',
        androidNotificationOngoing: true,
        androidResumeOnClick: true,
      );

      // 2. Setup AudioSession
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle interruptions (calls, etc)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(0.5);
          } else {
            _player.pause();
          }
        } else {
          if (event.type == AudioInterruptionType.duck) {
            _player.setVolume(1.0);
          } else {
            _player.play();
          }
        }
      });

      // Handle unplugging
      session.becomingNoisyEventStream.listen((_) => _player.pause());

      // 3. Setup Player Listeners
      _setupPlayerListeners();

      _isInit = true;
      debugPrint('✅ AudioManager initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing AudioManager: $e');
    }
  }

  void _setupPlayerListeners() {
    // Monitor Player State
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // Error Detection: Not playing but supposed to be?
      if (state.processingState == ProcessingState.completed) {
        _attemptReconnection(force: true);
      }

      notifyListeners();
    });

    // Monitor Errors
    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace st) {
        debugPrint('❌ Playback Error: $e');
        if (e is PlayerException) {
          debugPrint('Error code: ${e.code}');
          debugPrint('Error message: ${e.message}');
        }
        _attemptReconnection();
      },
    );
  }

  /// Play a station with robust strategy
  Future<void> play(model.Radio station) async {
    if (_currentStation?.id == station.id && _isPlaying) return;

    // cleanup
    _cancelReconnection();

    _currentStation = station;
    _retryCount = 0;
    notifyListeners();

    await _playInternal(station);
  }

  Future<void> _playInternal(model.Radio station) async {
    // Always try the first URL first, then others if available
    // But for each URL, we try varying headers

    for (int i = 0; i < station.streamUrl.length; i++) {
      final url = station.streamUrl[i];
      if (await _tryPlayUrl(url, station)) {
        return; // Success!
      }
    }

    // If all URLs fail
    debugPrint('❌ Failed to play station on all URLs');
    _attemptReconnection();
  }

  /// Try to play a specific URL with different Header strategies
  Future<bool> _tryPlayUrl(String url, model.Radio station) async {
    // Strategy 1: Standard Headers (Chrome/Android)
    if (await _configureAndPlay(url, station, _getStandardHeaders())) {
      return true;
    }

    // Strategy 2: Empty Headers (Sometimes safer)
    if (await _configureAndPlay(url, station, {})) return true;

    // Strategy 3: ICY / VLC Agent
    if (await _configureAndPlay(url, station, _getICYHeaders())) return true;

    return false;
  }

  Future<bool> _configureAndPlay(
      String url, model.Radio station, Map<String, String> headers) async {
    try {
      debugPrint('🎧 Trying to play: $url');
      debugPrint('   Headers: ${headers.keys.toList()}');

      // Force URI source - most robust for live streams
      final source = AudioSource.uri(
        Uri.parse(url),
        headers: headers,
        tag: MediaItem(
          id: station.id,
          title: station.name,
          artist: station.frequency,
          artUri: Uri.tryParse(station.logoUrl),
        ),
      );

      await _player.setAudioSource(source, preload: true);

      // Critical: Activate session before play
      final session = await AudioSession.instance;
      await session.setActive(true);

      await _player.play();

      // Verify we are actually playing
      if (_player.playing) {
        debugPrint('✅ SUCCESS: Playing $url');
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Method failed: $e');
    }
    return false;
  }

  Map<String, String> _getStandardHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': '*/*',
      'Icy-MetaData': '1',
    };
  }

  Map<String, String> _getICYHeaders() {
    return {
      'User-Agent':
          'VLC/3.0.18 LibVLC/3.0.18', // Often bypassed restrictive firewalls
      'Icy-MetaData': '1',
    };
  }

  void _attemptReconnection({bool force = false}) {
    if (_isReconnecting && !force) return;
    if (_currentStation == null) return;
    if (_retryCount > _maxRetries) {
      debugPrint('❌ Max retries reached, giving up.');
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _isReconnecting = true;
    _retryCount++;
    notifyListeners();

    debugPrint('🔄 Reconnecting in 3 seconds... (Attempt $_retryCount)');
    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(const Duration(seconds: 3), () async {
      if (_currentStation != null) {
        await _playInternal(_currentStation!);
        // If successful, _isReconnecting will be set to false by a successful play check or state update?
        // Actually _playInternal calls _tryPlayUrl which calls _player.play().
        // If successful, the logic naturally continues.
        // We should ensure flag reset if success.
        if (_player.playing) {
          _isReconnecting = false;
          _retryCount = 0;
          notifyListeners();
        }
      }
    });
  }

  void _cancelReconnection() {
    _reconnectionTimer?.cancel();
    _isReconnecting = false;
    _retryCount = 0;
  }

  Future<void> pause() async {
    _cancelReconnection();
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    _cancelReconnection();
    _currentStation = null;
    await _player.stop();
    notifyListeners();
  }
}
