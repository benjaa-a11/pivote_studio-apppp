import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  Future<void> setMuted(bool muted);

  void addListener(void Function() listener);
  void removeListener(void Function() listener);

  factory UnifiedVideoController.fromVideoPlayer(
      VideoPlayerController controller) {
    return HLSControllerAdapter(controller);
  }

  factory UnifiedVideoController.fromWeb(
      WebViewController controller, VideoState state) {
    return WebControllerAdapter(controller, state);
  }
}

/// State object to share data between JS channel and Adapter
class VideoState {
  bool isPlaying = false;
  bool isBuffering = false;
  bool isMuted = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  final List<VoidCallback> listeners = [];

  void notify() {
    for (var listener in listeners) {
      listener();
    }
  }

  void addListener(VoidCallback listener) {
    listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
  }

  void update({
    bool? playing,
    bool? buffering,
    bool? muted,
    double? pos,
    double? dur,
  }) {
    if (playing != null) isPlaying = playing;
    if (buffering != null) isBuffering = buffering;
    if (muted != null) isMuted = muted;
    if (pos != null) position = Duration(milliseconds: (pos * 1000).toInt());
    if (dur != null) duration = Duration(milliseconds: (dur * 1000).toInt());
    notify();
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
  Future<void> setMuted(bool muted) => controller.setVolume(muted ? 0.0 : 1.0);

  @override
  void addListener(void Function() listener) =>
      controller.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      controller.removeListener(listener);
}

/// Adapter for WebViewController
class WebControllerAdapter implements UnifiedVideoController {
  final WebViewController controller;
  final VideoState state;

  WebControllerAdapter(this.controller, this.state);

  @override
  bool get isPlaying => state.isPlaying;

  @override
  bool get isBuffering => state.isBuffering;

  @override
  bool get isInitialized => true;

  @override
  Duration get position => state.position;

  @override
  Duration get duration => state.duration;

  @override
  Future<void> play() => controller.runJavaScript(
      "try { window.play(); } catch(e) { console.log('Play error:', e); }");

  @override
  Future<void> pause() => controller.runJavaScript(
      "try { window.pause(); } catch(e) { console.log('Pause error:', e); }");

  @override
  Future<void> setVolume(double volume) => controller.runJavaScript(
      "try { document.querySelector('video').volume = $volume; } catch(e) {}");

  @override
  Future<void> setMuted(bool muted) {
    state.isMuted = muted;
    if (muted) {
      return controller
          .runJavaScript("try { window.mute(); } catch(e) { console.log('Mute error:', e); }");
    } else {
      return controller
          .runJavaScript("try { window.unmute(); } catch(e) { console.log('Unmute error:', e); }");
    }
  }

  @override
  void addListener(void Function() listener) => state.addListener(listener);

  @override
  void removeListener(void Function() listener) =>
      state.removeListener(listener);
}