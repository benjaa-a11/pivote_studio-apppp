import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'exoplayer_controller.dart';

/// Widget que muestra el ExoPlayer nativo de Android
class ExoPlayerView extends StatefulWidget {
  final ExoPlayerController controller;
  final Function(ExoPlayerController)? onCreated;

  const ExoPlayerView({
    super.key,
    required this.controller,
    this.onCreated,
  });

  @override
  State<ExoPlayerView> createState() => _ExoPlayerViewState();
}

class _ExoPlayerViewState extends State<ExoPlayerView> {
  int? _viewId;

  @override
  Widget build(BuildContext context) {
    // Solo Android soporta PlatformView de ExoPlayer
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'exoplayer_view',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          final androidViewController = PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'exoplayer_view',
            layoutDirection: TextDirection.ltr,
            creationParams: {},
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          );

          androidViewController.addOnPlatformViewCreatedListener((id) {
            debugPrint('🏗️ PlatformView created with ID: $id');
            _viewId = id;
            
            // Actualizar el controller con el viewId correcto
            final newController = ExoPlayerController(id);
            
            // Copiar los streams del controller anterior
            widget.controller.onStateChange.listen((state) {
              debugPrint('State forwarded: $state');
            });
            
            params.onPlatformViewCreated(id);
            widget.onCreated?.call(newController);
          });

          return androidViewController..create();
        },
      );
    }

    // Fallback para plataformas no soportadas
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'ExoPlayer solo está disponible en Android',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debugPrint('🗑️ ExoPlayerView disposed (viewId: $_viewId)');
    super.dispose();
  }
}