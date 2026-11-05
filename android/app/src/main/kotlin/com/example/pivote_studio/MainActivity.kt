package com.example.pivote_studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity — registra el PlatformView de Media3 ExoPlayer (Pivote Player).
 *
 * Nombre de tipo: "pivote-exoplayer" (mismo que antes, sin breaking change en Flutter).
 * Channels por instancia: pivote/player_methods_$viewId / pivote/player_events_$viewId
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "pivote-exoplayer",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}
