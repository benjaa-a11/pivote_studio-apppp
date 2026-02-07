package com.example.pivote_studio

import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

@UnstableApi
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Registrar la PlatformView Factory
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "exoplayer_view",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
            
        println("✅ ExoPlayerView registrado correctamente")
    }
}