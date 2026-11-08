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
import com.example.pivote_studio.player.NativeMediaPlayer

/**
 * Contenedor visual nativo liviano para Media3 [PlayerView].
 *
 * No posee ni crea instancias de ExoPlayer: simplemente presta su superficie
 * (`TextureView` o `SurfaceView`) al motor singleton [NativeMediaPlayer] mediante
 * `PlayerView.switchTargetView`, garantizando cero reproductores superpuestos.
 */
@OptIn(UnstableApi::class)
class NativePlayerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
    useTextureView: Boolean = true
) : FrameLayout(context, attrs, defStyleAttr) {

    var playerView: PlayerView
        private set

    var isUsingTextureView: Boolean = useTextureView
        private set

    private var currentResizeMode: Int = AspectRatioFrameLayout.RESIZE_MODE_FIT
    private var mediaPlayer: NativeMediaPlayer? = null

    init {
        setBackgroundColor(Color.BLACK)
        playerView = inflateMedia3PlayerView(useTextureView)
        addView(playerView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        isFocusable = true
        isFocusableInTouchMode = true
    }

    private fun inflateMedia3PlayerView(useTexture: Boolean): PlayerView {
        val layoutId = if (useTexture) {
            R.layout.native_player_view_texture
        } else {
            R.layout.native_player_view
        }

        return try {
            (LayoutInflater.from(context).inflate(layoutId, this, false) as PlayerView).apply {
                keepScreenOn = true
                useController = false
                resizeMode = currentResizeMode
                setShutterBackgroundColor(Color.TRANSPARENT)
            }
        } catch (_: Exception) {
            PlayerView(context).apply {
                keepScreenOn = true
                useController = false
                resizeMode = currentResizeMode
                setShutterBackgroundColor(Color.TRANSPARENT)
            }
        }
    }

    /**
     * Cambia en caliente entre `TextureView` y `SurfaceView` si un canal Widevine L1
     * requiere superficie segura de hardware o viceversa.
     */
    fun ensureSurfaceType(useTexture: Boolean) {
        if (isUsingTextureView == useTexture) return
        val oldView = playerView
        isUsingTextureView = useTexture
        val newView = inflateMedia3PlayerView(useTexture)

        removeView(oldView)
        addView(newView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        playerView = newView

        mediaPlayer?.let { engine ->
            PlayerView.switchTargetView(engine.player, oldView, newView)
        }
    }

    fun attachToEngine(engine: NativeMediaPlayer) {
        mediaPlayer = engine
        engine.attachView(this)
    }

    fun detachFromEngine() {
        mediaPlayer?.detachView(this)
        mediaPlayer = null
    }

    /**
     * Re-vincula la superficie de video actual para recuperar decoders que quedaron
     * sin renderizar tras cambios de resolución o ciclo de vida.
     */
    fun refreshVideoSurface() {
        val engine = mediaPlayer ?: return
        playerView.player = null
        playerView.player = engine.player
    }

    fun setResizeMode(mode: String?) {
        currentResizeMode = when (mode?.lowercase()) {
            "stretch", "fill" -> AspectRatioFrameLayout.RESIZE_MODE_FILL
            "zoom", "crop", "cover" -> AspectRatioFrameLayout.RESIZE_MODE_ZOOM
            "fixed_width" -> AspectRatioFrameLayout.RESIZE_MODE_FIXED_WIDTH
            "fixed_height" -> AspectRatioFrameLayout.RESIZE_MODE_FIXED_HEIGHT
            else -> AspectRatioFrameLayout.RESIZE_MODE_FIT
        }
        playerView.resizeMode = currentResizeMode
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
