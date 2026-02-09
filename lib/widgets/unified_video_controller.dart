import 'package:video_player/video_player.dart';
import 'exoplayer_controller_simple.dart';

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
  void addListener(void Function() listener) => controller.addListener(listener);
  
  @override
  void removeListener(void Function() listener) => controller.removeListener(listener);
}

/// Adapter for ExoPlayerController (DASH with DRM)
class ExoPlayerControllerAdapter implements UnifiedVideoController {
  final ExoPlayerController controller;
  
  ExoPlayerControllerAdapter(this.controller);
  
  @override
  bool get isPlaying => controller.isPlaying;
  
  @override
  bool get isBuffering => controller.state == PlayerState.buffering;
  
  @override
  bool get isInitialized => controller.state == PlayerState.ready || controller.state == PlayerState.buffering;
  
  @override
  Duration get position => Duration.zero; // ExoPlayer maneja posición internamente
  
  @override
  Duration get duration => Duration.zero; // ExoPlayer maneja duración internamente
  
  @override
  Future<void> play() => controller.play();
  
  @override
  Future<void> pause() => controller.pause();
  
  @override
  Future<void> setVolume(double volume) => controller.setVolume(volume);
  
  @override
  void addListener(void Function() listener) {
    // ExoPlayer usa streams, no listeners directos
    // Los eventos se manejan via streams en el widget
  }
  
  @override
  void removeListener(void Function() listener) {
    // No applicable for ExoPlayer streams
  }
}