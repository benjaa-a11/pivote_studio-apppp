import 'package:video_player/video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';

/// Unified interface for both VideoPlayerController and BetterPlayerController
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

/// Adapter for DASH BetterPlayerController
class DASHControllerAdapter implements UnifiedVideoController {
  final BetterPlayerController controller;

  DASHControllerAdapter(this.controller);

  @override
  bool get isPlaying => controller.isPlaying() ?? false;

  @override
  bool get isBuffering {
    // BetterPlayer doesn't expose buffering state directly, so we approximate
    return !isInitialized || (!isPlaying && position == Duration.zero);
  }

  @override
  bool get isInitialized => controller.isVideoInitialized() ?? false;

  @override
  Duration get position =>
      controller.videoPlayerController?.value.position ?? Duration.zero;

  @override
  Duration get duration =>
      controller.videoPlayerController?.value.duration ?? Duration.zero;

  @override
  Future<void> play() async => controller.play();

  @override
  Future<void> pause() async => controller.pause();

  @override
  Future<void> setVolume(double volume) async => controller.setVolume(volume);

  @override
  void addListener(void Function() listener) {
    // BetterPlayer uses event listeners, so we adapt it
    controller.videoPlayerController?.addListener(listener);
  }

  @override
  void removeListener(void Function() listener) {
    controller.videoPlayerController?.removeListener(listener);
  }
}
