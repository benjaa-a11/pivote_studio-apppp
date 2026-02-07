import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exoplayer_controller.dart';

/// Widget que muestra la vista nativa de ExoPlayer en Android
class ExoPlayerView extends StatefulWidget {
  final ExoPlayerController controller;
  final Function(ExoPlayerController) onCreated;

  const ExoPlayerView({
    super.key,
    required this.controller,
    required this.onCreated,
  });

  @override
  State<ExoPlayerView> createState() => _ExoPlayerViewState();
}

class _ExoPlayerViewState extends State<ExoPlayerView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const Center(
        child: Text('ExoPlayer solo está disponible en Android'),
      );
    }

    return AndroidView(
      viewType: 'exoplayer_view',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: const <String, dynamic>{},
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  void _onPlatformViewCreated(int id) {
    // Actualizamos el controller con el ID real de la vista
    // Aunque en este caso el controller ya tiene un ID placeholder,
    // el canal se basará en el ID que pasamos aquí si quisiéramos ser dinámicos.
    // Pero según la implementación actual, el controller usa el viewId.

    // Si el controller es compartido o se crea antes, podemos re-inicializarlo
    // o simplemente llamar al callback.
    widget.onCreated(widget.controller);
  }
}
