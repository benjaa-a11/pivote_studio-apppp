package com.example.pivote_studio.player

import android.content.Context
import android.net.Uri
import androidx.annotation.OptIn
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.dash.DashMediaSource
import androidx.media3.exoplayer.dash.DefaultDashChunkSource
import androidx.media3.exoplayer.drm.DrmSessionManager
import androidx.media3.exoplayer.drm.DrmSessionManagerProvider
import androidx.media3.exoplayer.hls.DefaultHlsExtractorFactory
import androidx.media3.exoplayer.hls.HlsMediaSource
import androidx.media3.exoplayer.source.MediaSource
import androidx.media3.exoplayer.source.ProgressiveMediaSource
import androidx.media3.exoplayer.upstream.DefaultLoadErrorHandlingPolicy
import androidx.media3.extractor.DefaultExtractorsFactory
import androidx.media3.extractor.ts.DefaultTsPayloadReaderFactory
import androidx.media3.extractor.ts.TsExtractor
import com.example.pivote_studio.data.StreamChannel
import com.example.pivote_studio.data.StreamFormat
import com.example.pivote_studio.drm.PivoteDrmManager
import com.example.pivote_studio.network.StreamHttpDataSourceFactory

/**
 * Fábrica de MediaSources unificada y optimizada para TV en vivo (Media3 ExoPlayer).
 *
 * Soporta:
 *   • DASH (.mpd)       → DashMediaSource (live con SegmentTimeline/UTCTiming, multi-periodo, CENC y CBCS)
 *   • HLS (.m3u8)       → HlsMediaSource (playlists rotativas, #EXT-X-DISCONTINUITY, TS/fMP4, AES-128, SAMPLE-AES)
 *   • Progresivo / TS   → ProgressiveMediaSource (MPEG-TS continuo directo con MODE_MULTI_PMT, MP4, MKV, AAC)
 */
@OptIn(UnstableApi::class)
object StreamMediaSourceFactory {

    private const val SUBTAG = "MediaSource"

    /**
     * Orden de fallback exigido cuando el formato no puede inferirse por extensión ni MIME:
     * probar DASH → HLS → progresivo/TS.
     */
    val PROBE_ORDER = listOf(StreamFormat.DASH, StreamFormat.HLS, StreamFormat.PROGRESSIVE)

    fun createMediaSource(
        context: Context,
        channel: StreamChannel,
        format: StreamFormat,
        forceL3: Boolean = channel.forceWidevineL3,
        allowChunklessHls: Boolean = true,
        useProxy: Boolean = false
    ): MediaSource {
        require(channel.originalUrl.isNotBlank()) { "URL del canal no puede estar vacía" }

        val targetUrl = if (useProxy) {
            NativePlayerConfig.wrapWithProxy(
                rawUrl = channel.originalUrl.trim(),
                proxyTemplateOrBase = channel.proxyUrl,
                referer = channel.headers["Referer"]
            )
        } else {
            channel.originalUrl.trim()
        }

        val uri = Uri.parse(targetUrl)
        require(uri.scheme != null) { "URL inválida: falta el esquema (http/https)" }

        val dataSourceFactory = StreamHttpDataSourceFactory.create(context, channel.headers, targetUrl)

        val licenseFactory = StreamHttpDataSourceFactory.createHttp(
            channel.headers + channel.licenseHeaders,
            channel.licenseUrl ?: targetUrl
        )
        val drmManager: DrmSessionManager? =
            PivoteDrmManager.buildDrmSessionManager(channel, licenseFactory, forceL3)
        val drmProvider: DrmSessionManagerProvider? =
            drmManager?.let { manager -> DrmSessionManagerProvider { manager } }

        val errorPolicy = DefaultLoadErrorHandlingPolicy(NativePlayerConfig.LOAD_ERROR_MIN_RETRIES)

        NativePlayerConfig.logI(
            SUBTAG,
            "MediaSource → format=$format drm=${channel.drmScheme}(${channel.encryptionScheme}) " +
                "l3=$forceL3 chunkless=$allowChunklessHls proxy=$useProxy " +
                "url=${PlayerErrorMapper.sanitizeUrl(targetUrl)}"
        )

        // Para HLS NO se fuerza un offset objetivo: con segmentos de 6-10 s un target de 3.5 s
        // queda por debajo de la distancia mínima segura al borde y provoca rebuffering/saltos
        // constantes. Se respeta el HOLD-BACK/PART-HOLD-BACK del propio playlist.
        val liveConfig = MediaItem.LiveConfiguration.Builder()
            .apply {
                if (format == StreamFormat.DASH) {
                    setTargetOffsetMs(NativePlayerConfig.LIVE_TARGET_OFFSET_MS)
                    setMinOffsetMs(NativePlayerConfig.LIVE_MIN_OFFSET_MS)
                    setMaxOffsetMs(NativePlayerConfig.LIVE_MAX_OFFSET_MS)
                }
            }
            .setMinPlaybackSpeed(NativePlayerConfig.LIVE_MIN_SPEED)
            .setMaxPlaybackSpeed(NativePlayerConfig.LIVE_MAX_SPEED)
            .build()

        val mediaItemBuilder = MediaItem.Builder()
            .setUri(uri)
            .setMediaId(targetUrl)
            .setLiveConfiguration(liveConfig)
            .apply {
                when (format) {
                    StreamFormat.DASH -> setMimeType(MimeTypes.APPLICATION_MPD)
                    StreamFormat.HLS -> setMimeType(MimeTypes.APPLICATION_M3U8)
                    else -> Unit
                }
            }

        val mediaItem = mediaItemBuilder.build()

        // NOTA CRÍTICA PARA M3U8 y MPEG-TS EN VIVO:
        //   1. No activar FLAG_DETECT_ACCESS_UNITS porque muchos encoders IPTV omiten delimitadores
        //      AUD NAL y dejan a H264Reader esperando indefinidamente el primer frame ("solo audio").
        //   2. FLAG_ALLOW_NON_IDR_KEYFRAMES permite arrancar video rápido en streams cuyos keyframes
        //      usan recovery points en vez de IDR estrictos.
        //   3. FLAG_IGNORE_SPLICE_INFO_STREAM evita fallos de parseo ante marcadores SCTE-35 de publicidad.
        val tsPayloadFlags = DefaultTsPayloadReaderFactory.FLAG_ALLOW_NON_IDR_KEYFRAMES or
            DefaultTsPayloadReaderFactory.FLAG_IGNORE_SPLICE_INFO_STREAM

        return when (format) {
            StreamFormat.DASH -> DashMediaSource.Factory(
                DefaultDashChunkSource.Factory(dataSourceFactory),
                dataSourceFactory
            )
                .setFallbackTargetLiveOffsetMs(NativePlayerConfig.LIVE_TARGET_OFFSET_MS)
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

            StreamFormat.PROGRESSIVE, StreamFormat.SMOOTH, StreamFormat.UNKNOWN -> {
                val extractors = DefaultExtractorsFactory()
                    .setConstantBitrateSeekingEnabled(true)
                    .setConstantBitrateSeekingAlwaysEnabled(true)
                    .setTsExtractorMode(TsExtractor.MODE_MULTI_PMT)
                    .setTsExtractorFlags(tsPayloadFlags)

                ProgressiveMediaSource.Factory(dataSourceFactory, extractors)
                    .setLoadErrorHandlingPolicy(errorPolicy)
                    .setContinueLoadingCheckIntervalBytes(256 * 1024)
                    .apply { drmProvider?.let { setDrmSessionManagerProvider(it) } }
                    .createMediaSource(mediaItem)
            }
        }
    }
}
