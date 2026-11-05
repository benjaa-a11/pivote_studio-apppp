package com.example.pivote_studio.player

import android.net.Uri
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MediaSource
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.drm.PivoteDrmManager
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Fábrica de MediaSources unificada para Media3 ExoPlayer.
 *
 * Soporta:
 *   • HLS (m3u8)                 → HlsMediaSource
 *   • DASH (mpd)                 → DashMediaSource
 *   • HTTP progresivo (mp4, ts…) → DefaultMediaSourceFactory
 *
 * DRM soportado por tipo:
 *   • ClearKey estático (kid/key pares o JSON W3C) — via LocalMediaDrmCallback
 *   • Widevine Modular (CENC / CBCS) — via HttpMediaDrmCallback con servidor remoto
 *
 * Los headers HTTP se inyectan a nivel de DataSource.Factory, garantizando que
 * cada chunk de segmento HLS/DASH también los lleve (no solo el manifiesto).
 */
@OptIn(UnstableApi::class)
object StreamMediaSourceFactory {

    private const val TAG = "StreamMediaSourceFactory"

    /**
     * Punto de entrada principal: construye el [MediaSource] completo a partir de [StreamChannel].
     */
    fun createMediaSource(channel: StreamChannel): MediaSource {
        require(channel.originalUrl.isNotBlank()) { "URL del canal no puede estar vacía" }

        val httpFactory  = StreamHttpDataSourceFactory.create(channel.headers)
        val uri          = Uri.parse(channel.originalUrl)
        val drmConfig    = PivoteDrmManager.buildDrmConfiguration(channel)
        val drmManager   = PivoteDrmManager.buildDrmSessionManager(channel, httpFactory)

        Log.d(TAG, "Creando MediaSource: url=${sanitize(channel.originalUrl)} " +
                   "drm=${channel.drmScheme} hls=${channel.isHls()} dash=${channel.isDash()}")

        return when {
            channel.isDash() -> createDashSource(uri, httpFactory, drmConfig, drmManager, channel)
            channel.isHls()  -> createHlsSource(uri, httpFactory, drmConfig, drmManager)
            else             -> createProgressiveSource(uri, httpFactory, drmConfig, drmManager)
        }
    }

    // ── Dash ─────────────────────────────────────────────────────────────────────

    private fun createDashSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager,
        channel: StreamChannel
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMimeType(MimeTypes.APPLICATION_MPD)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        return DashMediaSource.Factory(httpFactory)
            .apply { setDrmSessionManagerProvider { drmManager } }
            .createMediaSource(mediaItem)
    }

    // ── HLS ──────────────────────────────────────────────────────────────────────

    private fun createHlsSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMimeType(MimeTypes.APPLICATION_M3U8)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        return HlsMediaSource.Factory(httpFactory)
            .setAllowChunklessPreparation(true)
            .apply { setDrmSessionManagerProvider { drmManager } }
            .createMediaSource(mediaItem)
    }

    // ── Progresivo (MP4, TS, directo HTTP) ───────────────────────────────────────

    private fun createProgressiveSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        return DefaultMediaSourceFactory(httpFactory)
            .apply { setDrmSessionManagerProvider { drmManager } }
            .createMediaSource(mediaItem)
    }

    // ── Utils ─────────────────────────────────────────────────────────────────────

    private fun sanitize(url: String): String {
        return try {
            val uri = Uri.parse(url)
            "${uri.scheme}://${uri.host}${uri.path}"
        } catch (_: Exception) {
            url.take(40)
        }
    }
}
