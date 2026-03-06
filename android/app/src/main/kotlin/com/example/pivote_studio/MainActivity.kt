package com.example.pivote_studio

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity — registers ExoPlayer PlatformView for native DASH/DRM playback
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native ExoPlayer PlatformView
        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "pivote-exoplayer",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
    }
}