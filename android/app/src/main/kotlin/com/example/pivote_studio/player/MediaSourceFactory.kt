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
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.drm.PivoteDrmManager
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Fábrica de MediaSources unificada para Media3 ExoPlayer.
 *
 * Soporta:
 *   • HLS (m3u8)                 → HlsMediaSource
 *   • DASH (mpd)                 → DashMediaSource
 *   • HTTP progresivo / TS live  → DefaultMediaSourceFactory con extractores TS configurados
 *
 * Inyección DRM:
 *   • ClearKey: DrmSessionManager local con claves en memoria
 *   • Widevine: DrmConfiguration remota + HttpMediaDrmCallback
 */
@OptIn(UnstableApi::class)
object StreamMediaSourceFactory {

    private const val TAG = "StreamMediaSourceFactory"

    fun createMediaSource(channel: StreamChannel): MediaSource {
        require(channel.originalUrl.isNotBlank()) { "URL del canal no puede estar vacía" }

        val httpFactory = StreamHttpDataSourceFactory.create(channel.headers, requestUrl = channel.originalUrl)
        val uri = Uri.parse(channel.originalUrl)
        val drmConfig = PivoteDrmManager.buildDrmConfiguration(channel)
        val drmManager = PivoteDrmManager.buildDrmSessionManager(channel, httpFactory)

        Log.d(TAG, "Creando MediaSource: url=${sanitize(channel.originalUrl)} " +
                   "drm=${channel.drmScheme} hls=${channel.isHls()} dash=${channel.isDash()}")

        return when {
            channel.isDash() -> createDashSource(uri, httpFactory, drmConfig, drmManager)
            channel.isHls()  -> createHlsSource(uri, httpFactory, drmConfig, drmManager)
            else             -> createProgressiveSource(uri, httpFactory, drmConfig, drmManager)
        }
    }

    private fun createDashSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager?
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMimeType(MimeTypes.APPLICATION_MPD)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        val dashFactory = DashMediaSource.Factory(httpFactory)
        if (drmManager != null) {
            dashFactory.setDrmSessionManagerProvider { drmManager }
        }

        return dashFactory.createMediaSource(mediaItem)
    }

    private fun createHlsSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager?
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMimeType(MimeTypes.APPLICATION_M3U8)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        val hlsFactory = HlsMediaSource.Factory(httpFactory)
            .setAllowChunklessPreparation(true)

        if (drmManager != null) {
            hlsFactory.setDrmSessionManagerProvider { drmManager }
        }

        return hlsFactory.createMediaSource(mediaItem)
    }

    private fun createProgressiveSource(
        uri: Uri,
        httpFactory: DataSource.Factory,
        drmConfig: MediaItem.DrmConfiguration?,
        drmManager: androidx.media3.exoplayer.drm.DrmSessionManager?
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .apply { if (drmConfig != null) setDrmConfiguration(drmConfig) }
            .build()

        // Extractores con soporte completo para MPEG-TS en flujos IPTV en vivo continuos
        val extractorsFactory = DefaultExtractorsFactory()
            .setConstantBitrateSeekingEnabled(true)
            .setTsExtractorFlags(
                DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES or
                DefaultTsPayloadReaderFactory.FLAG_DETECT_ACCESS_UNITS
            )

        val factory = DefaultMediaSourceFactory(httpFactory, extractorsFactory)
        if (drmManager != null) {
            factory.setDrmSessionManagerProvider { drmManager }
        }

        return factory.createMediaSource(mediaItem)
    }

    private fun sanitize(url: String): String {
        return try {
            val uri = Uri.parse(url)
            "${uri.scheme}://${uri.host}${uri.path}"
        } catch (_: Exception) {
            url.take(40)
        }
    }
}
