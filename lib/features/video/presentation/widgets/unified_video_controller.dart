import 'package:video_player/video_player.dart';

/// Unified interface for all video controllers
abstract class UnifiedVideoController {
  bool get isPlaying;
  bool get isBuffering;
  bool get isInitialized;
  Duration get position;
  Duration get duration;

  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double volume);

  void addListener(void Function() listener);
  void removeListener(void Function() listener);

  // Factory methods
  factory UnifiedVideoController.fromVideoPlayer(
      VideoPlayerController controller) {
    return HLSControllerAdapter(controller);
  }
}

/// Adapter for HLS VideoPlayerController
class HLSControllerAdapter implements UnifiedVideoController {
  final VideoPlayerController controller;

  HLSControllerAdapter(this.controller);

  @override
  bool get isPlaying => controller.value.isPlaying;

  @override
  bool get isBuffering => controller.value.isBuffering;

  @override
  bool get isInitialized => controller.value.isInitialized;

  @override
  Duration get position => controller.value.position;

  @override
  Duration get duration => controller.value.duration;

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);

  @override
  void addListener(void Function() listener) =>
      controller.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      controller.removeListener(listener);
}
