package com.example.pivote_studio

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity para registrar PlatformView de ExoPlayer
 */
class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        Log.d(TAG, "🚀 Configurando Flutter Engine")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        
        // Registrar ExoPlayerView
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "exoplayer_view",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
        
        Log.d(TAG, "✅ ExoPlayerView registrado")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
    }
}
EOF
cat /mnt/user-data/outputs/MainActivity.kt
Salida

package com.example.pivote_studio

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity para registrar PlatformView de ExoPlayer
 */
class MainActivity: FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        Log.d(TAG, "🚀 Configurando Flutter Engine")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
        
        // Registrar ExoPlayerView
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "exoplayer_view",
                ExoPlayerViewFactory(flutterEngine.dartExecutor.binaryMessenger)
            )
        
        Log.d(TAG, "✅ ExoPlayerView registrado")
        Log.d(TAG, "═══════════════════════════════════════════════════════")
    }
}