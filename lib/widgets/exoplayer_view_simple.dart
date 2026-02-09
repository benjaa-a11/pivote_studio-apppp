import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exoplayer_controller_simple.dart';

/// Widget de ExoPlayer para Android - Optimizado para IPTV M3U8
class ExoPlayerView extends StatefulWidget {
  final Function(ExoPlayerController)? onCreated;

  const ExoPlayerView({
    super.key,
    this.onCreated,
  });

  @override
  State<ExoPlayerView> createState() => _ExoPlayerViewState();
}

class _ExoPlayerViewState extends State<ExoPlayerView> {
  ExoPlayerController? _controller;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(
        child: Text('ExoPlayer solo disponible en Android'),
      );
    }

    return AndroidView(
      viewType: 'exoplayer_view',
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int id) {
    debugPrint('🎬 ExoPlayerView created with ID: $id');

    _controller = ExoPlayerController(id);

    if (widget.onCreated != null) {
      widget.onCreated!(_controller!);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
