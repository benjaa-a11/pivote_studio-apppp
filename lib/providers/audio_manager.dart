import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import '../models/radio.dart' as radio_model;
import '../services/background_audio_service.dart';

enum AudioManagerStatus { initial, loading, playing, paused, error }

class AudioManager extends ChangeNotifier {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal() {
    initialize();
  }

  bool _isInitialized = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // State
  AudioManagerStatus _status = AudioManagerStatus.initial;
  radio_model.Radio? _currentRadio;
  String? _errorMessage;

  // Getters
  AudioManagerStatus get status => _status;
  radio_model.Radio? get currentRadio => _currentRadio;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _status == AudioManagerStatus.playing;
  bool get isLoading => _status == AudioManagerStatus.loading;

  // Streams for UI consumption
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await AudioServiceHelper.init();

    // Listen to player state changes
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final processingState = playerState.processingState;
      final playing = playerState.playing;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        // If we are already playing (user hit play), keep showing playing state (Pause btn)
        // unless it's the initial load.
        if (playing && _status == AudioManagerStatus.playing) {
          // Do nothing, keep status as playing so UI shows Pause button
        } else {
          _status = AudioManagerStatus.loading;
        }
      } else if (!playing) {
        // Only set to paused if we are not in initial or error state mostly
        if (_status != AudioManagerStatus.error) {
          _status = AudioManagerStatus.paused;
        }
      } else if (processingState == ProcessingState.ready) {
        _status = AudioManagerStatus.playing;
      } else if (processingState == ProcessingState.completed) {
        _status = AudioManagerStatus.paused;
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }

      // Override: If playing is true and we are ready/buffering, let's just say playing
      // so the user sees the Pause button.
      if (playing &&
          (processingState == ProcessingState.ready ||
              processingState == ProcessingState.buffering)) {
        _status = AudioManagerStatus.playing;
      }

      notifyListeners();
    });

    // Listen to playback errors
    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('A stream error occurred: $e');
        _status = AudioManagerStatus.error;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> playRadio(radio_model.Radio radio) async {
    // If selecting the same radio that is already loaded
    if (_currentRadio?.id == radio.id) {
      if (_status == AudioManagerStatus.playing) {
        pause();
      } else {
        resume();
      }
      return;
    }

    try {
      _currentRadio = radio;
      _status = AudioManagerStatus.loading;
      _errorMessage = null;
      notifyListeners();

      // Setup Background Audio Service MediaItem
      final mediaItem = MediaItem(
        id: radio.id,
        album: "Radio en Vivo",
        title: radio.name,
        artist: radio.frequency,
        artUri: Uri.parse(radio.logoUrl),
      );

      // Pass media item to existing service if we needed to,
      // but here we are using just_audio directly for simplicity in manager
      // and letting background service hooks handle the notification updates ideally.
      // However, looking at the existing background_audio_service, it sets the player source.
      // Let's integrate with the existing connection pattern.

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Icy-MetaData': '1',
      };

      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // Update AudioService
      if (AudioServiceHelper.handler != null) {
        AudioServiceHelper.handler!.mediaItem.add(mediaItem);
      }

      await _audioPlayer.setUrl(
        radio.streamUrl.first,
        headers: headers,
      );

      await _audioPlayer.play();
    } catch (e) {
      _status = AudioManagerStatus.error;
      _errorMessage = "No se pudo conectar a la emisora. Revisa tu conexión.";
      debugPrint("Error playing radio: $e");
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentRadio = null;
    _status = AudioManagerStatus.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
