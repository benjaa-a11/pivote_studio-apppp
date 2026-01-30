import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import '../models/radio.dart' as model;

/// Manager for handling live audio streams using just_audio
class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _player = AudioPlayer();
  model.Radio? _currentStation;
  bool _isInit = false;

  // Streams for UI consumption
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  model.Radio? get currentStation => _currentStation;
  bool get isPlaying => _player.playing;

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

  /// Play a specific radio station
  Future<void> play(model.Radio station) async {
    if (_currentStation?.id == station.id && _player.playing) return;

    try {
      _currentStation = station;
      notifyListeners();

      // Use first available stream URL
      final url = station.streamUrl.isNotEmpty ? station.streamUrl[0] : '';
      if (url.isEmpty) throw Exception('No stream URL available');

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

      await _player.setAudioSource(source);
      _player.play();
      debugPrint('🎧 Playing: ${station.name}');
    } catch (e) {
      debugPrint('❌ Error playing station ${station.name}: $e');
      _currentStation = null;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStation = null;
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
