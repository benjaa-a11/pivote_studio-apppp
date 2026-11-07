package com.example.pivote_studio.player

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.dash.DefaultDashChunkSource
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManagerProvider
import androidx.media3.exoplayer.hls.DefaultHlsExtractorFactory
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.rtsp.RtspMediaSource
import androidx.media3.exoplayer.smoothstreaming.DefaultSsChunkSource
import androidx.media3.exoplayer.smoothstreaming.SsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory
import androidx.media3.extractor.ts.TsExtractor
import com.example.pivote_studio.data.DrmScheme
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.data.StreamFormat
import com.example.pivote_studio.drm.PivoteDrmManager
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Fábrica de MediaSources unificada para Media3 ExoPlayer.
 *
 * Soporta:
 *   • HLS (m3u8)       → HlsMediaSource (TS/fMP4, AES-128, SAMPLE-AES, Widevine, ClearKey)
 *   • DASH (mpd)       → DashMediaSource (CENC / CBCS, multi-periodo, live)
 *   • Smooth Streaming → SsMediaSource (PlayReady)
 *   • RTSP             → RtspMediaSource
 *   • Progresivo       → ProgressiveMediaSource (mp4, mkv, ts live, mp3, aac…)
 */
@OptIn(UnstableApi::class)
object StreamMediaSourceFactory {

    private const val TAG = "StreamMediaSource"

    /** Reintentos rápidos por segmento/manifiesto para no congelar el failover. */
    private const val LOAD_RETRIES = 2

    /** Orden de prueba cuando el formato no puede inferirse de la URL/tipo. */
    val PROBE_ORDER = listOf(StreamFormat.HLS, StreamFormat.PROGRESSIVE, StreamFormat.DASH)

    fun createMediaSource(
        context: Context,
        channel: StreamChannel,
        format: StreamFormat,
        forceL3: Boolean = channel.forceWidevineL3,
        allowChunklessHls: Boolean = true
    ): MediaSource {
        require(channel.originalUrl.isNotBlank()) { "URL del canal no puede estar vacía" }
        val uri = Uri.parse(channel.originalUrl.trim())
        require(uri.scheme != null) { "URL inválida: falta el esquema (http/https/rtsp)" }

        val dataSourceFactory = StreamHttpDataSourceFactory.create(context, channel.headers, channel.originalUrl)

        val licenseFactory = StreamHttpDataSourceFactory.createHttp(
            channel.headers + channel.licenseHeaders,
            channel.licenseUrl ?: channel.originalUrl
        )
        val drmManager: DrmSessionManager? =
            PivoteDrmManager.buildDrmSessionManager(channel, licenseFactory, forceL3)
        val drmProvider: DrmSessionManagerProvider? = drmManager?.let { m -> DrmSessionManagerProvider { m } }

        val errorPolicy = DefaultLoadErrorHandlingPolicy(LOAD_RETRIES)

        Log.i(TAG, "MediaSource → format=$format drm=${channel.drmScheme} l3=$forceL3 chunkless=$allowChunklessHls " +
            "url=${PlayerErrorMapper.sanitizeUrl(channel.originalUrl)}")

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)
            .setMediaId(channel.originalUrl)
            .apply {
                when (format) {
                    StreamFormat.HLS    -> setMimeType(MimeTypes.APPLICATION_M3U8)
                    StreamFormat.DASH   -> setMimeType(MimeTypes.APPLICATION_MPD)
                    StreamFormat.SMOOTH -> setMimeType(MimeTypes.APPLICATION_SS)
                    StreamFormat.RTSP   -> setMimeType(MimeTypes.APPLICATION_RTSP)
                    else                -> Unit
                }
            }
            .setLiveConfiguration(
                MediaItem.LiveConfiguration.Builder()
                    .setMinPlaybackSpeed(0.97f)
                    .setMaxPlaybackSpeed(1.03f)
                    .build()
            )

        // Si es Widevine remoto, agregamos también DrmConfiguration en el MediaItem
        if (channel.drmScheme == DrmScheme.WIDEVINE && !channel.licenseUrl.isNullOrBlank()) {
            val drmConfig = MediaItem.DrmConfiguration.Builder(C.WIDEVINE_UUID)
                .setLicenseUri(channel.licenseUrl)
                .setMultiSession(true)
                .apply {
                    if (channel.licenseHeaders.isNotEmpty()) {
                        setLicenseRequestHeaders(channel.licenseHeaders)
                    }
                }
                .build()
            mediaItemBuilder.setDrmConfiguration(drmConfig)
        }

        val mediaItem = mediaItemBuilder.build()

        // NOTA CRÍTICA PARA M3U8: No activar FLAG_DETECT_ACCESS_UNITS ya que muchos streams
        // HLS/TS en vivo (Pluto, Wowza, Flussonic, Mediastream, enlaces claros) omiten NAL AUD
        // y provocan que H264Reader se quede esperando indefinidamente el primer frame.
        val tsPayloadFlags = DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES or
            DefaultTsPayloadReaderFactory.FLAG_IGNORE_SPLICE_INFO_STREAM

        return when (format) {
            StreamFormat.DASH -> DashMediaSource.Factory(
                DefaultDashChunkSource.Factory(dataSourceFactory), dataSourceFactory
            )
                .setLoadErrorHandlingPolicy(errorPolicy)
                .apply { drmProvider?.let { setDrmSessionManagerProvider(it) } }
                .createMediaSource(mediaItem)

            StreamFormat.HLS -> HlsMediaSource.Factory(dataSourceFactory)
                .setExtractorFactory(
                    DefaultHlsExtractorFactory(
                        tsPayloadFlags,
                        /* exposeCea608WhenMissingDeclarations = */ false
                    )
                )
                .setAllowChunklessPreparation(allowChunklessHls)
                .setTimestampAdjusterInitializationTimeoutMs(8_000L)
                .setLoadErrorHandlingPolicy(errorPolicy)
                .apply { drmProvider?.let { setDrmSessionManagerProvider(it) } }
                .createMediaSource(mediaItem)

            StreamFormat.SMOOTH -> SsMediaSource.Factory(
                DefaultSsChunkSource.Factory(dataSourceFactory), dataSourceFactory
            )
                .setLoadErrorHandlingPolicy(errorPolicy)
                .apply { drmProvider?.let { setDrmSessionManagerProvider(it) } }
                .createMediaSource(mediaItem)

            StreamFormat.RTSP -> RtspMediaSource.Factory()
                .setForceUseRtpTcp(true)
                .setTimeoutMs(10_000)
                .createMediaSource(mediaItem)

            StreamFormat.PROGRESSIVE, StreamFormat.UNKNOWN -> {
                val extractors = DefaultExtractorsFactory()
                    .setConstantBitrateSeekingEnabled(true)
                    .setConstantBitrateSeekingAlwaysEnabled(true)
                    .setTsExtractorMode(TsExtractor.MODE_MULTI_PMT)
                    .setTsExtractorFlags(tsPayloadFlags)
                    .setTsTimestampSearchBytes(188 * 1_200)
                ProgressiveMediaSource.Factory(dataSourceFactory, extractors)
                    .setLoadErrorHandlingPolicy(errorPolicy)
                    .setContinueLoadingCheckIntervalBytes(512 * 1024)
                    .apply { drmProvider?.let { setDrmSessionManagerProvider(it) } }
                    .createMediaSource(mediaItem)
            }
        }
    }
}
