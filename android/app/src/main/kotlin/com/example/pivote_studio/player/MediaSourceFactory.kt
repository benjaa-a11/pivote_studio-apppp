package com.example.pivote_studio.player

import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.source.MediaSource
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.drm.ClearKeyManager
import com.example.pivote_studio.drm.ClearKeyParser
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Fábrica de MediaSources para Media3 ExoPlayer.
 * Conecta StreamChannel -> HTTP DataSource -> ClearKey DRM -> DashMediaSource.
 * Diseñado de forma modular para admitir DASH/ClearKey nativo y preparado para HLS/MP4 futuros.
 */
@OptIn(UnstableApi::class)
object StreamMediaSourceFactory {

    /**
     * Construye un MediaSource completamente configurado a partir de los datos del canal.
     */
    fun createMediaSource(channel: StreamChannel): MediaSource {
        if (channel.originalUrl.isBlank()) {
            throw IllegalArgumentException("La URL original del canal no puede estar vacía")
        }

        val httpFactory = StreamHttpDataSourceFactory.create(channel.headers)
        val uri = Uri.parse(channel.originalUrl)

        // 1. Configuración de DRM (ClearKey)
        val drmSessionManager: DrmSessionManager? = if (channel.isClearKey() && channel.hasDrm()) {
            val clearKeys = ClearKeyParser.parse(channel.drmLicenseUri)
            ClearKeyManager.createDrmSessionManager(clearKeys)
        } else {
            null
        }

        // 2. Detección y creación del MediaSource según el tipo de stream
        return if (channel.isDash()) {
            createDashMediaSource(uri, httpFactory, drmSessionManager)
        } else {
            createDefaultMediaSource(uri, httpFactory, drmSessionManager)
        }
    }

    private fun createDashMediaSource(
        uri: Uri,
        httpFactory: androidx.media3.datasource.DataSource.Factory,
        drmSessionManager: DrmSessionManager?
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .setMimeType(MimeTypes.APPLICATION_MPD)
            .build()

        val dashFactory = DashMediaSource.Factory(httpFactory)
        if (drmSessionManager != null) {
            dashFactory.setDrmSessionManagerProvider { drmSessionManager }
        }

        return dashFactory.createMediaSource(mediaItem)
    }

    private fun createDefaultMediaSource(
        uri: Uri,
        httpFactory: androidx.media3.datasource.DataSource.Factory,
        drmSessionManager: DrmSessionManager?
    ): MediaSource {
        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .build()

        val factory = DefaultMediaSourceFactory(httpFactory)
        if (drmSessionManager != null) {
            factory.setDrmSessionManagerProvider { drmSessionManager }
        }

        return factory.createMediaSource(mediaItem)
    }
}
