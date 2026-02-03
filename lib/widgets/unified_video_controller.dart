import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:better_player_plus/better_player_plus.dart';

/// Unified interface for both VideoPlayerController and BetterPlayerController
/// This allows CustomVideoControls to work with both HLS and DASH players
abstract class UnifiedVideoController {
  bool get isBuffering;
  bool get isPlaying;
  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);
}

/// Adapter for standard VideoPlayerController (HLS/MP4)
class HLSControllerAdapter extends UnifiedVideoController {
  final VideoPlayerController _controller;

  HLSControllerAdapter(this._controller);

  @override
  bool get isBuffering => _controller.value.isBuffering;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);
}

/// Adapter for BetterPlayerController (DASH with DRM)
class DASHControllerAdapter extends UnifiedVideoController {
  final BetterPlayerController _controller;
  VoidCallback? _listener;

  DASHControllerAdapter(this._controller);

  @override
  bool get isBuffering => _controller.isBuffering() ?? false;

  @override
  bool get isPlaying => _controller.isPlaying() ?? false;

  @override
  void addListener(VoidCallback listener) {
    _listener = listener;
    // Better Player uses event streams, we need to listen to state changes
    _controller.addEventsListener((event) {
      if (_listener != null) {
        _listener!();
      }
    });
  }

  @override
  void removeListener(VoidCallback listener) {
    // Better Player doesn't have a direct removeListener
    // The listener will be cleaned up when controller is disposed
    _listener = null;
  }
}
