import 'package:video_player/video_player.dart';
import 'package:media_kit/media_kit.dart';

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

  factory UnifiedVideoController.fromMediaKit(Player player) {
    return MediaKitControllerAdapter(player);
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

/// Adapter for MediaKit Player
class MediaKitControllerAdapter implements UnifiedVideoController {
  final Player player;

  MediaKitControllerAdapter(this.player);

  @override
  bool get isPlaying => player.state.playing;

  @override
  bool get isBuffering => player.state.buffering;

  @override
  bool get isInitialized => true; // MediaKit is initialized on creation

  @override
  Duration get position => player.state.position;

  @override
  Duration get duration => player.state.duration;

  @override
  Future<void> play() => player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> setVolume(double volume) => player.setVolume(volume * 100);

  @override
  void addListener(void Function() listener) {
    player.stream.playing.listen((_) => listener());
    player.stream.buffering.listen((_) => listener());
    player.stream.position.listen((_) => listener());
  }

  @override
  void removeListener(void Function() listener) {
    // In MediaKit, we'd ideally manage the subscription, but for now this is the interface
  }
}
