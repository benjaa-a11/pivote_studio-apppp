import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class BackgroundAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _currentRadioId;
  String? _currentRadioName;

  BackgroundAudioHandler() {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _audioPlayer.playingStream.listen((playing) {
      _updatePlaybackState();
    });

    _audioPlayer.processingStateStream.listen((state) {
      _updatePlaybackState();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _updatePlaybackState();
    });

  }

  Future<void> playRadio({
    required String radioId,
    required String radioName,
    required String radioLogoUrl,
    required String streamUrl,
  }) async {
    try {
      _currentRadioId = radioId;
      _currentRadioName = radioName;

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
        'Icy-MetaData': '1',
      };

      // Stop current playback
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // Set audio source with timeout
      await _audioPlayer.setUrl(streamUrl, headers: headers).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      // Update media item
      mediaItem.add(MediaItem(
        id: radioId,
        title: radioName,
        artUri: Uri.parse(radioLogoUrl),
        album: 'Radio',
        duration: null, // Radio streams don't have a fixed duration
        playable: true,
      ));

      // Start playback
      await _audioPlayer.play();
      _updatePlaybackState();
    } catch (e) {
      debugPrint('Error playing radio in background: $e');
      // Update state to reflect error
      _updatePlaybackState();
      rethrow;
    }
  }

  Future<void> pauseRadio() async {
    await _audioPlayer.pause();
    _updatePlaybackState();
  }

  Future<void> resumeRadio() async {
    await _audioPlayer.play();
    _updatePlaybackState();
  }

  Future<void> stopRadio() async {
    await _audioPlayer.stop();
    _currentRadioId = null;
    _currentRadioName = null;
    mediaItem.add(null);
    _updatePlaybackState();
  }

  bool get isPlaying => _audioPlayer.playing;
  String? get currentRadioId => _currentRadioId;
  String? get currentRadioName => _currentRadioName;

  void _updatePlaybackState() {
    final isPlaying = _audioPlayer.playing;
    final processingState = _audioPlayer.processingState;

    PlaybackState playbackState;

    switch (processingState) {
      case ProcessingState.idle:
        playbackState = PlaybackState(
          controls: [
            MediaControl.play,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0],
          processingState: AudioProcessingState.idle,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
          speed: 1.0,
          queueIndex: 0,
        );
        break;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        playbackState = PlaybackState(
          controls: [
            MediaControl.pause,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0],
          processingState: AudioProcessingState.loading,
          playing: isPlaying,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: 0,
        );
        break;
      case ProcessingState.ready:
        playbackState = PlaybackState(
          controls: isPlaying
              ? [
                  MediaControl.pause,
                  MediaControl.stop,
                ]
              : [
                  MediaControl.play,
                  MediaControl.stop,
                ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1],
          processingState: AudioProcessingState.ready,
          playing: isPlaying,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: 0,
        );
        break;
      case ProcessingState.completed:
        playbackState = PlaybackState(
          controls: [
            MediaControl.play,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0],
          processingState: AudioProcessingState.completed,
          playing: false,
          updatePosition: _audioPlayer.position,
          bufferedPosition: _audioPlayer.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: 0,
        );
        break;
    }

    this.playbackState.value = playbackState;
  }

  @override
  Future<void> play() => resumeRadio();

  @override
  Future<void> pause() => pauseRadio();

  @override
  Future<void> stop() => stopRadio();

  @override
  Future<void> seek(Duration position) async {
    // Radio streams don't support seeking
    return;
  }

  @override
  Future<void> onTaskRemoved() async {
    // Don't stop playback when task is removed
    // This allows audio to continue playing in background
    return;
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Don't stop playback when notification is deleted
    return;
  }
}

// Helper class to initialize audio service
class AudioServiceHelper {
  static BackgroundAudioHandler? _handler;

  static Future<BackgroundAudioHandler> init() async {
    _handler = await AudioService.init(
      builder: () => BackgroundAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.pivote.radio',
        androidNotificationChannelName: 'Radio en vivo',
        androidNotificationChannelDescription:
            'Reproducción de radio en segundo plano',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
        androidShowNotificationBadge: true,
      ),
    );
    return _handler!;
  }

  static BackgroundAudioHandler? get handler => _handler;

  static Future<void> stop() async {
    await _handler?.stop();
    _handler = null;
  }
}