package com.example.pivote_studio

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity — registra el PlatformView de Media3 ExoPlayer (Pivote Player)
 * y gestiona el modo Picture-in-Picture (PiP) nativo de Android (API 26+).
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine.platformViewsController.registry
            .registerViewFactory(
                "pivote-exoplayer",
                ExoPlayerViewFactory(
                    messenger = flutterEngine.dartExecutor.binaryMessenger,
                    pipController = { enterPlayerPipMode() }
                )
            )
    }

    private fun enterPlayerPipMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) return false
        return runCatching {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
        }.getOrDefault(false)
    }
}
