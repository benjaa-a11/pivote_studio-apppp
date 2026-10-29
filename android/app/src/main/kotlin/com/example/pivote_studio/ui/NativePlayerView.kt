package com.example.pivote_studio.ui

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.AttributeSet
import android.util.Base64
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.annotation.OptIn
import androidx.media3.common.Tracks
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import android.view.LayoutInflater
import com.example.pivote_studio.R
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.player.NativeMediaPlayer
import com.example.pivote_studio.player.NativePlayerListener
import com.example.pivote_studio.player.PlayerErrorInfo

/**
 * Vista nativa de reproducción basada en Media3 PlayerView.
 * Diseñada para funcionar tanto en dispositivos táctiles como en Android TV mediante navegación D-Pad.
 * Incluye superposición para título, icono (con soporte offline para Data URI Base64),
 * indicador de carga y estados de error.
 */
@OptIn(UnstableApi::class)
class NativePlayerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr), NativePlayerListener {

    private val playerView: PlayerView = try {
        (LayoutInflater.from(context).inflate(R.layout.native_player_view, this, false) as PlayerView).apply {
            keepScreenOn = true
        }
    } catch (_: Exception) {
        PlayerView(context).apply {
            useController = false
            resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
            setShutterBackgroundColor(Color.TRANSPARENT)
            keepScreenOn = true
        }
    }

    private val loadingProgressBar: ProgressBar = ProgressBar(context).apply {
        visibility = View.GONE
    }

    private val titleTextView: TextView = TextView(context).apply {
        setTextColor(Color.WHITE)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        setShadowLayer(4f, 2f, 2f, Color.BLACK)
        visibility = View.GONE
    }

    private val iconImageView: ImageView = ImageView(context).apply {
        visibility = View.GONE
        scaleType = ImageView.ScaleType.FIT_CENTER
    }

    private val headerLayout: LinearLayout = LinearLayout(context).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER_VERTICAL
        setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        addView(iconImageView, LinearLayout.LayoutParams(dpToPx(32), dpToPx(32)).apply {
            marginEnd = dpToPx(10)
        })
        addView(titleTextView, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ))
    }

    private val errorTextView: TextView = TextView(context).apply {
        setTextColor(Color.parseColor("#FF5252"))
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        gravity = Gravity.CENTER
        visibility = View.GONE
        setBackgroundColor(Color.parseColor("#99000000"))
        setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(12))
    }

    private var mediaPlayer: NativeMediaPlayer? = null
    private var externalListener: NativePlayerListener? = null

    init {
        setBackgroundColor(Color.BLACK)

        // Habilitar navegación por control remoto (Android TV / D-Pad)
        isFocusable = true
        isFocusableInTouchMode = true
        descendantFocusability = FOCUS_AFTER_DESCENDANTS

        // Agregar vistas
        addView(playerView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))

        addView(headerLayout, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.TOP or Gravity.START
        })

        addView(loadingProgressBar, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.CENTER
        })

        addView(errorTextView, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            gravity = Gravity.BOTTOM
        })

        // Soporte de clic táctil
        setOnClickListener {
            togglePlayPause()
        }
    }

    /**
     * Vincula el NativeMediaPlayer a la PlayerView y escucha sus eventos.
     */
    fun attachPlayer(player: NativeMediaPlayer, listener: NativePlayerListener? = null) {
        mediaPlayer = player
        externalListener = listener
        player.listener = this
        playerView.player = player.player
        requestFocus()
    }

    fun detachPlayer() {
        playerView.player = null
        mediaPlayer?.listener = null
        mediaPlayer = null
        externalListener = null
    }

    /**
     * Actualiza el encabezado del canal (título e icono).
     */
    fun bindChannel(channel: StreamChannel) {
        titleTextView.text = channel.name
        titleTextView.visibility = if (channel.name.isNotBlank()) View.VISIBLE else View.GONE

        val iconData = channel.icono
        if (!iconData.isNullOrBlank()) {
            val bitmap = decodeIconIfDataUri(iconData)
            if (bitmap != null) {
                iconImageView.setImageBitmap(bitmap)
                iconImageView.visibility = View.VISIBLE
            } else {
                iconImageView.visibility = View.GONE
            }
        } else {
            iconImageView.visibility = View.GONE
        }
    }

    /**
     * Decodifica un icono local si tiene formato Data URI Base64: "data:image/...;base64,..."
     * No realiza peticiones a internet.
     */
    private fun decodeIconIfDataUri(iconData: String): Bitmap? {
        return try {
            if (iconData.startsWith("data:image/", ignoreCase = true)) {
                val base64Part = iconData.substringAfter("base64,", "")
                if (base64Part.isNotEmpty()) {
                    val bytes = Base64.decode(base64Part, Base64.DEFAULT)
                    BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                } else null
            } else null
        } catch (_: Exception) {
            null
        }
    }

    fun showLoading(show: Boolean) {
        loadingProgressBar.visibility = if (show) View.VISIBLE else View.GONE
    }

    fun showError(message: String?) {
        if (message != null) {
            errorTextView.text = message
            errorTextView.visibility = View.VISIBLE
        } else {
            errorTextView.visibility = View.GONE
        }
    }

    private fun togglePlayPause() {
        val player = mediaPlayer ?: return
        if (player.isPlaying) {
            player.pause()
        } else {
            player.play()
        }
    }

    // ── Navegación Android TV (D-Pad) ──────────────────────────────────────────

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_DPAD_CENTER,
            KeyEvent.KEYCODE_ENTER -> {
                togglePlayPause()
                return true
            }
            KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                togglePlayPause()
                return true
            }
            KeyEvent.KEYCODE_MEDIA_PLAY -> {
                mediaPlayer?.play()
                return true
            }
            KeyEvent.KEYCODE_MEDIA_PAUSE -> {
                mediaPlayer?.pause()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    // ── Callbacks de NativePlayerListener ──────────────────────────────────────

    override fun onReady() {
        showLoading(false)
        showError(null)
        externalListener?.onReady()
    }

    override fun onBuffering() {
        showLoading(true)
        externalListener?.onBuffering()
    }

    override fun onPlaying() {
        showLoading(false)
        showError(null)
        externalListener?.onPlaying()
    }

    override fun onPaused() {
        externalListener?.onPaused()
    }

    override fun onEnded() {
        showLoading(false)
        externalListener?.onEnded()
    }

    override fun onError(errorInfo: PlayerErrorInfo) {
        showLoading(false)
        showError(errorInfo.technicalMessage)
        externalListener?.onError(errorInfo)
    }

    override fun onTracksChanged(tracks: Tracks) {
        externalListener?.onTracksChanged(tracks)
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}
