package com.example.pivote_studio.ui

import android.content.Context
import android.graphics.Color
import android.util.AttributeSet
import android.view.KeyEvent
import android.view.LayoutInflater
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.example.pivote_studio.R
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.player.NativeMediaPlayer

/**
 * Vista nativa limpia basada en Media3 PlayerView con TextureView.
 *
 * Por qué TextureView + Shutter transparente:
 *   • En Flutter AndroidView, SurfaceView perfora la ventana o queda oculto detrás de la capa
 *     de Skia/Impeller causando pantalla negra con audio. TextureView se compone directamente
 *     en el lienzo de la jerarquía AndroidView sin agujeros ni desincronización.
 *   • setShutterBackgroundColor(Color.TRANSPARENT) evita que el shutter interno de Media3
 *     tape el video si hay transiciones de pista o eventos post-frame.
 */
@OptIn(UnstableApi::class)
class NativePlayerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    useTextureView: Boolean = true
) : FrameLayout(context, attrs, defStyleAttr) {

    val playerView: PlayerView

    private var mediaPlayer: NativeMediaPlayer? = null

    init {
        setBackgroundColor(Color.BLACK)

        val layoutId = if (useTextureView) {
            R.layout.native_player_view_texture
        } else {
            R.layout.native_player_view
        }

        playerView = try {
            (LayoutInflater.from(context).inflate(layoutId, this, false) as PlayerView).apply {
                keepScreenOn = true
                useController = false
                resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                setShutterBackgroundColor(Color.TRANSPARENT)
            }
        } catch (_: Exception) {
            PlayerView(context).apply {
                keepScreenOn = true
                useController = false
                resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
                setShutterBackgroundColor(Color.TRANSPARENT)
            }
        }

        addView(playerView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        isFocusable = true
        isFocusableInTouchMode = true
    }

    fun attachPlayer(player: NativeMediaPlayer) {
        mediaPlayer = player
        playerView.player = player.player
    }

    fun detachPlayer() {
        playerView.player = null
        mediaPlayer = null
    }

    fun bindChannel(channel: StreamChannel) {
        // Sin superposiciones nativas: toda la UI se dibuja en Flutter
    }

    fun setResizeMode(mode: String?) {
        val resizeMode = when (mode?.lowercase()) {
            "stretch", "fill" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
            "zoom", "crop" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            "fixed_width" -> AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
            "fixed_height" -> AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT
            else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
        playerView.resizeMode = resizeMode
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        val player = mediaPlayer ?: return super.onKeyDown(keyCode, event)
        when (keyCode) {
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER,
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                if (player.isPlaying) player.pause() else player.play()
                return true
            }
            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                player.play()
                return true
            }
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                player.pause()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
