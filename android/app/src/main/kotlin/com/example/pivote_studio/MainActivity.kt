package com.example.pivote_studio

import android.util.Log
import androidx.annotation.NonNull
import androidx.media3.common.util.UnstableApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

@UnstableApi
class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "🔧 Configurando FlutterEngine...")
        
        // Registrar la PlatformView Factory
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "exoplayer_view",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
        
        Log.d(TAG, "✅ ExoPlayerView registrado correctamente")
    }
}