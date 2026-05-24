import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:pivote/features/radio/data/models/radio.dart' as radio_model;
import 'package:pivote/features/radio/data/services/background_audio_service.dart';

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

  // Volume control
  double get volume => _audioPlayer.volume;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;
  Future<void> setVolume(double value) async {
    await _audioPlayer.setVolume(value);
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      final processingState = playerState.processingState;
      final playing = playerState.playing;

      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        _status = AudioManagerStatus.loading;
      } else if (!playing) {
        _status = AudioManagerStatus.paused;
      } else if (processingState != ProcessingState.completed) {
        _status = AudioManagerStatus.playing;
      } else {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }

      notifyListeners();
    });

    try {
      await AudioServiceHelper.init();
    } catch (e) {
      debugPrint("AudioService error: $e");
    }

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
    // Si es la misma radio y ya está cargada
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
    // Al resumir, reconectamos al stream en vivo
    if (_currentRadio != null) {
      try {
        _status = AudioManagerStatus.loading;
        notifyListeners();

        final headers = {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': '*/*',
          'Connection': 'keep-alive',
          'Icy-MetaData': '1',
        };

        // Reconectar al stream para obtener el audio en vivo
        await _audioPlayer.setUrl(
          _currentRadio!.streamUrl.first,
          headers: headers,
        );

        await _audioPlayer.play();
      } catch (e) {
        _status = AudioManagerStatus.error;
        _errorMessage = "No se pudo reconectar a la emisora.";
        debugPrint("Error resuming radio: $e");
        notifyListeners();
      }
    }
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
