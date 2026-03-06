import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:pivote/features/video/presentation/widgets/custom_video_controls.dart';
import 'package:pivote/features/video/presentation/widgets/unified_video_controller.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';
import 'package:pivote/features/video/presentation/widgets/player_enums.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
// PIVO SHAKA PLAYER v6.0 — Professional MPD/DASH + ClearKey DRM
// ════════════════════════════════════════════════════════════════════════════
//
// Full-featured WebView player using Shaka Player to handle DASH/MPD streams
// with CENC ClearKey DRM decryption. Uses the same controls, lifecycle
// management, and FlutterBridge protocol as PivoProPlayer.
//
// Features:
//   • Shaka Player v4.7 with ABR, stall detection, health monitoring
//   • ClearKey DRM (k1/k2) injected at load time
//   • Autoplay engine: unmuted → muted+delayed-unmute fallback
//   • FlutterBridge JS↔Flutter messaging (state sync, errors, buffering)
//   • CustomVideoControls integration (fullscreen, mute, aspect ratio)
//   • Loading failsafe, iframe timeout, retry system
//   • WidgetsBindingObserver lifecycle (pause/resume)
//
// ════════════════════════════════════════════════════════════════════════════

class PivoShakaPlayer extends StatefulWidget {
  final String url;
  final String? k1;
  final String? k2;
  final String channelName;
  final int currentServer;
  final int totalServers;
  final VoidCallback onRefresh;
  final VoidCallback? onAllServersFailed;

  const PivoShakaPlayer({
    super.key,
    required this.url,
    this.k1,
    this.k2,
    required this.channelName,
    required this.currentServer,
    required this.totalServers,
    required this.onRefresh,
    this.onAllServersFailed,
  });

  @override
  State<PivoShakaPlayer> createState() => _PivoShakaPlayerState();
}

class _PivoShakaPlayerState extends State<PivoShakaPlayer>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late final WebViewController _wvc;
  late final UnifiedVideoController _unified;
  final VideoState _videoState = VideoState();

  bool _isFullscreen = false;
  AspectRatioType _arType = AspectRatioType.ratio16_9;
  bool _disposed = false;
  bool _videoStarted = false;
  int _retries = 0;

  Timer? _stateMonitor;
  Timer? _loadingFailsafe;
  Timer? _loadTimeout;
  StreamSubscription? _stateSub;

  @override
  bool get wantKeepAlive => true;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🌐 PivoShakaPlayer v6.0 — ${widget.channelName}');
    debugPrint(
        '   MPD: ${widget.url.substring(0, widget.url.length.clamp(0, 80))}');
    if (widget.k1 != null) debugPrint('   DRM: ClearKey enabled');
    _initWebView();
    _startStateMonitor();
    _startLoadingFailsafe();
    _startLoadTimeout();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _js('window.pause()');
    } else if (state == AppLifecycleState.resumed) {
      _js('window.play()');
    }
  }

  @override
  void didUpdateWidget(PivoShakaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.k1 != widget.k1) {
      _videoStarted = false;
      _retries = 0;
      _videoState.reset();
      _loadShakaHtml();
      _startLoadingFailsafe();
      _startLoadTimeout();
    }
  }

  // ── WebView Init ─────────────────────────────────────────────────────────

  void _initWebView() {
    _wvc = WebViewController();

    // ╔══════════════════════════════════════════════════════════════╗
    // ║ CRITICAL: Allow autoplay without user gesture (Android)     ║
    // ╚══════════════════════════════════════════════════════════════╝
    final platform = _wvc.platform;
    if (platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      platform.setMediaPlaybackRequiresUserGesture(false);
    }

    _wvc
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _onMessageFromHtml,
      );

    _unified = UnifiedVideoController.fromWeb(_wvc, _videoState);
    _stateSub = _videoState.stateChanges.listen(_onStateChange);

    _loadShakaHtml();
  }

  // ── HTML → Flutter Messages ──────────────────────────────────────────────

  void _onMessageFromHtml(JavaScriptMessage msg) {
    if (_disposed || !mounted) return;
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      final type = data['type'] as String?;

      // Sync state if present
      if (data['state'] != null) {
        _syncState(data['state'] as Map<String, dynamic>);
      }

      switch (type) {
        case 'playerReady':
          debugPrint('✅ Shaka player ready');
          break;
        case 'playingStarted':
          _onPlayingStarted(data);
          break;
        case 'loadingStart':
          _onLoadingStart();
          break;
        case 'stateUpdate':
          if (data['state'] != null) {
            _syncState(data['state'] as Map<String, dynamic>);
          }
          break;
        case 'buffering':
          setState(() => _videoState.update(
                buffering: data['state'] == 'waiting',
              ));
          break;
        case 'audioEnabled':
          setState(() => _videoState.update(muted: false));
          break;
        case 'audioDisabled':
          setState(() => _videoState.update(muted: true));
          break;
        case 'streamStalled':
          _onStreamStalled();
          break;
        case 'serverChange':
          _onServerChange(data);
          break;
        case 'error':
          _onHtmlError(data);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ Shaka msg parse: $e');
    }
  }

  void _syncState(Map<String, dynamic> s) {
    _videoState.update(
      playing: s['isPlaying'] as bool?,
      buffering: s['isBuffering'] as bool?,
      muted: s['isMuted'] as bool?,
      loading: s['isLoading'] as bool?,
      bufHealth: s['bufferHealth'] as int?,
      stalled: s['stallDetected'] as bool?,
      servIndex: s['serverIndex'] as int?,
      totalServ: s['totalServers'] as int?,
    );
  }

  void _onLoadingStart() {
    _loadingFailsafe?.cancel();
    _startLoadingFailsafe();
    if (mounted) {
      setState(() => _videoState.update(loading: true, error: false));
    }
  }

  void _onPlayingStarted(Map<String, dynamic> data) {
    _loadingFailsafe?.cancel();
    _loadTimeout?.cancel();
    _videoStarted = true;
    _retries = 0;

    final muted = data['muted'] as bool? ?? false;
    if (mounted) {
      setState(() => _videoState.update(
            loading: false,
            playing: true,
            buffering: false,
            muted: muted,
            error: false,
          ));
    }
    debugPrint('▶️ Shaka playing — muted: $muted');
  }

  void _onStreamStalled() {
    debugPrint('⚠️ Shaka stream stalled');
    if (mounted) setState(() => _videoState.update(stalled: true));
    Future.delayed(const Duration(seconds: 4), () {
      if (!_disposed && mounted && _videoState.stallDetected) {
        _js('window.nextServer()');
      }
    });
  }

  void _onServerChange(Map<String, dynamic> data) {
    final idx = data['serverIndex'] as int? ?? 1;
    final total = data['totalServers'] as int?;
    if (mounted) {
      setState(() => _videoState.update(
            loading: true,
            servIndex: idx - 1,
            totalServ: total,
          ));
    }
  }

  void _onHtmlError(Map<String, dynamic> data) {
    debugPrint('❌ Shaka error: ${data['code']} — ${data['message']}');
    _retries++;
    if (_retries > PlayerConfig.maxIframeRetries) {
      if (mounted) {
        setState(() => _videoState.update(
              loading: false,
              error: true,
              errorMsg: data['message'] as String? ?? 'Error de reproducción',
            ));
      }
      widget.onAllServersFailed?.call();
    } else {
      if (mounted) {
        setState(() => _videoState.update(loading: true, error: false));
      }
      Future.delayed(
        const Duration(milliseconds: PlayerConfig.quickRetryDelayMs),
        () {
          if (!_disposed && mounted) _loadShakaHtml();
        },
      );
    }
  }

  // ── Monitoring ────────────────────────────────────────────────────────────

  void _startStateMonitor() {
    _stateMonitor?.cancel();
    _stateMonitor = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_disposed || !mounted) return;
      _js('if(window.FlutterBridge)window.FlutterBridge.sendStateUpdate()');
    });
  }

  void _startLoadingFailsafe() {
    _loadingFailsafe?.cancel();
    _loadingFailsafe = Timer(PlayerConfig.loadingFailsafeTimeout, () {
      if (!_disposed && mounted && _videoState.isLoading) {
        debugPrint('⏱ Shaka loading failsafe');
        setState(() => _videoState.update(loading: false));
      }
    });
  }

  void _startLoadTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(PlayerConfig.iframeLoadTimeout, () {
      if (_disposed || !mounted || _videoStarted) return;
      debugPrint('⏱ Shaka load timeout');
      _retries++;
      if (_retries > PlayerConfig.maxIframeRetries) {
        setState(() => _videoState.update(
              loading: false,
              error: true,
              errorMsg: 'El servidor no respondió a tiempo',
            ));
        widget.onAllServersFailed?.call();
      } else {
        setState(() => _videoState.update(loading: true, error: false));
        _loadShakaHtml();
        _startLoadTimeout();
      }
    });
  }

  void _onStateChange(VideoStateChange change) {
    if (_disposed || !mounted) return;
    if (change.hasChanged('isLoading') ||
        change.hasChanged('hasError') ||
        change.hasChanged('isPlaying')) {
      setState(() {});
    }
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  Future<void> _toggleMute() => _js('window.toggleMute()');

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }

  void _changeAspectRatio() => setState(() => _arType = _arType.next);

  double _getAspectRatio() {
    switch (_arType) {
      case AspectRatioType.ratio4_3:
        return 4 / 3;
      case AspectRatioType.stretch:
        final s = MediaQuery.of(context).size;
        return s.width / s.height;
      default:
        return 16 / 9;
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _videoState.reset();
      _retries = 0;
      _videoStarted = false;
    });
    _loadingFailsafe?.cancel();
    _loadTimeout?.cancel();
    _startLoadingFailsafe();
    _startLoadTimeout();
    _loadShakaHtml();
    widget.onRefresh.call();
  }

  Future<void> _js(String script) async {
    if (_disposed) return;
    try {
      await _wvc.runJavaScript('(function(){try{$script}catch(e){}})()');
    } catch (_) {}
  }

  // ── Shaka HTML Generation ─────────────────────────────────────────────────

  void _loadShakaHtml() {
    final safeUrl = widget.url.replaceAll('"', '\\"').replaceAll("'", "\\'");
    final safeK1 = (widget.k1 ?? '').replaceAll('"', '\\"');
    final safeK2 = (widget.k2 ?? '').replaceAll('"', '\\"');

    final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="robots" content="noindex, nofollow" />
    <meta name="referrer" content="no-referrer" />
    <meta name="theme-color" content="#000000" />
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            width: 100%; height: 100%;
            overflow: hidden; background: #000;
            -webkit-tap-highlight-color: transparent;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            user-select: none;
        }
        #player { width: 100%; height: 100%; position: relative; background: #000; }
        video {
            width: 100%; height: 100%;
            display: block; background: #000;
            object-fit: contain;
            transform: translateZ(0);
            -webkit-transform: translateZ(0);
        }
        video::-webkit-media-controls,
        video::-webkit-media-controls-enclosure,
        video::-webkit-media-controls-panel { display: none !important; }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/shaka-player/4.7.0/shaka-player.compiled.min.js"></script>
</head>
<body>
    <div id="player">
        <video id="videoElement" autoplay playsinline webkit-playsinline
               x5-playsinline x5-video-player-type="h5" preload="auto" muted></video>
    </div>
<script>
// ═══════════════════════════════════════
// PIVOPRO SHAKA ENGINE v6.0
// ═══════════════════════════════════════

const CONFIG = {
    STALL_THRESHOLD_MS: 8000,
    HEALTH_CHECK_INTERVAL: 3000,
    AUTOPLAY_UNMUTE_DELAY: 150
};

// ── Flutter Bridge ─────────────────────
const FlutterBridge = (() => {
    let _queue = [];
    let _ready = false;
    let _healthTimer = null;

    function _getState() {
        const v = document.getElementById('videoElement');
        if (!v) return {};
        return {
            isPlaying: !v.paused && !v.ended,
            isBuffering: false,
            isMuted: v.muted,
            isLoading: false,
            currentTime: v.currentTime,
            duration: v.duration || 0,
            volume: v.volume,
            error: null,
            stallDetected: false,
            bufferHealth: 100
        };
    }

    function _send(type, extra = {}) {
        const msg = JSON.stringify({
            type,
            timestamp: Date.now(),
            state: _getState(),
            ...extra
        });
        if (_ready && window.FlutterChannel) {
            try { window.FlutterChannel.postMessage(msg); } catch(_) {}
        } else {
            _queue.push(msg);
        }
    }

    function _flush() {
        if (!window.FlutterChannel) return;
        _ready = true;
        while (_queue.length > 0) {
            try { window.FlutterChannel.postMessage(_queue.shift()); } catch(_) {}
        }
    }

    const _poll = setInterval(() => {
        if (window.FlutterChannel) { clearInterval(_poll); _flush(); }
    }, 100);

    function _startHealthSync() {
        if (_healthTimer) return;
        _healthTimer = setInterval(() => _send('stateUpdate'), 4000);
    }

    return {
        send: _send,
        sendError: (c, m) => _send('error', { code: c, message: m }),
        sendStateUpdate: () => _send('stateUpdate'),
        startHealthSync: _startHealthSync
    };
})();

// ── Health Monitor ─────────────────────
class HealthMonitor {
    constructor(video) {
        this.video = video;
        this._lastTime = 0;
        this._stallStart = null;
        this._timer = null;
    }
    start() {
        this.stop();
        this._timer = setInterval(() => this._check(), CONFIG.HEALTH_CHECK_INTERVAL);
    }
    stop() {
        if (this._timer) { clearInterval(this._timer); this._timer = null; }
    }
    _check() {
        if (!this.video) return;
        const ct = this.video.currentTime;
        const playing = !this.video.paused && !this.video.ended;
        if (playing) {
            if (ct === this._lastTime) {
                if (!this._stallStart) this._stallStart = Date.now();
                const stalled = Date.now() - this._stallStart;
                if (stalled >= CONFIG.STALL_THRESHOLD_MS) {
                    FlutterBridge.send('streamStalled', { currentTime: ct, stallDuration: stalled });
                    this._stallStart = null;
                }
            } else {
                this._stallStart = null;
            }
        }
        this._lastTime = ct;
    }
}

// ── Autoplay Engine ────────────────────
async function _attemptAutoplay(video) {
    try {
        video.muted = false;
        video.volume = 1.0;
        await video.play();
        return 'unmuted';
    } catch(e) {}

    try {
        video.muted = true;
        await video.play();
        setTimeout(() => {
            try {
                video.muted = false;
                video.volume = 1.0;
                FlutterBridge.send('audioEnabled', { auto: true, method: 'delayed-unmute' });
            } catch(_) {}
        }, CONFIG.AUTOPLAY_UNMUTE_DELAY);
        return 'muted-then-unmuted';
    } catch(e) {
        FlutterBridge.sendError('AUTOPLAY_BLOCKED', 'No se puede reproducir automáticamente');
        return 'blocked';
    }
}

// ── Flutter API ────────────────────────
let shakaPlayer = null;
let videoEl = null;
let healthMon = null;

window.unmute = () => { if(videoEl) { videoEl.muted = false; FlutterBridge.send('audioEnabled'); return true; } return false; };
window.mute = () => { if(videoEl) { videoEl.muted = true; FlutterBridge.send('audioDisabled'); return true; } return false; };
window.toggleMute = () => {
    if (!videoEl) return null;
    videoEl.muted = !videoEl.muted;
    FlutterBridge.send(videoEl.muted ? 'audioDisabled' : 'audioEnabled', { muted: videoEl.muted });
    return videoEl.muted;
};
window.isMuted = () => videoEl ? videoEl.muted : null;
window.setVolume = (v) => { if(videoEl) { videoEl.volume = Math.max(0,Math.min(1,v)); FlutterBridge.send('volumeChanged',{volume:videoEl.volume}); return true; } return false; };
window.getVolume = () => videoEl ? videoEl.volume : null;
window.play = () => {
    if (!videoEl) return Promise.resolve(false);
    return videoEl.play().then(() => true).catch(() => false);
};
window.pause = () => { if(videoEl) { videoEl.pause(); return true; } return false; };
window.isPlaying = () => videoEl ? (!videoEl.paused && !videoEl.ended) : null;
window.getPlayerState = () => ({});
window.nextServer = () => { FlutterBridge.sendError('SERVER_EXHAUSTED','Servidor MPD falló'); return true; };
window.retryCurrentServer = () => { initShaka(); return true; };

// ── Shaka Configuration ────────────────
function _configurarShaka(player) {
    player.configure({
        streaming: {
            bufferingGoal: 8,
            rebufferingGoal: 2,
            bufferBehind: 20,
            retryParameters: { maxAttempts: 4, baseDelay: 500, backoffFactor: 2, timeout: 12000 },
            ignoreTextStreamFailures: true,
            jumpLargeGaps: true,
            smallGapLimit: 0.5,
            segmentPrefetchLimit: 2,
            stallEnabled: true,
            stallThreshold: 1,
            stallSkip: 0.1
        },
        manifest: {
            retryParameters: { maxAttempts: 4, baseDelay: 500, timeout: 12000 },
            defaultPresentationDelay: 8,
            dash: { autoCorrectDrift: true, ignoreMinBufferTime: false }
        },
        abr: {
            enabled: true,
            useNetworkInformation: true,
            defaultBandwidthEstimate: 3000000,
            switchInterval: 8,
            bandwidthDowngradeTarget: 0.95,
            bandwidthUpgradeTarget: 0.85
        },
        preferredAudioLanguage: 'es',
        preferredAudioChannelCount: 2
    });
}

// ── Init ───────────────────────────────
async function initShaka() {
    shaka.polyfill.installAll();
    if (!shaka.Player.isBrowserSupported()) {
        FlutterBridge.sendError('NOT_SUPPORTED', 'Navegador no soportado');
        return;
    }

    if (healthMon) healthMon.stop();
    if (shakaPlayer) { try { await shakaPlayer.destroy(); } catch(_) {} shakaPlayer = null; }

    const playerDiv = document.getElementById('player');
    playerDiv.innerHTML = '<video id="videoElement" autoplay playsinline webkit-playsinline x5-playsinline preload="auto" muted></video>';
    videoEl = document.getElementById('videoElement');

    shakaPlayer = new shaka.Player(videoEl);
    _configurarShaka(shakaPlayer);
    healthMon = new HealthMonitor(videoEl);

    shakaPlayer.addEventListener('error', (ev) => {
        FlutterBridge.sendError('SHAKA_ERR', ev.detail ? ev.detail.message || 'Error Shaka' : 'Error Shaka');
    });

    videoEl.addEventListener('playing', () => {
        healthMon.start();
        FlutterBridge.send('playingStarted', { muted: videoEl.muted });
    });
    videoEl.addEventListener('waiting', () => FlutterBridge.send('buffering', { state: 'waiting' }));
    videoEl.addEventListener('canplay', () => FlutterBridge.send('buffering', { state: 'ready' }));
    videoEl.addEventListener('pause', () => FlutterBridge.send('playbackPaused'));
    videoEl.addEventListener('volumechange', () => FlutterBridge.send('stateUpdate'));
    videoEl.addEventListener('error', () => {
        FlutterBridge.sendError('VIDEO_ERR', 'Error de video');
    });

    FlutterBridge.send('loadingStart');

    try {
        const k1 = "$safeK1";
        const k2 = "$safeK2";
        if (k1 && k2) {
            shakaPlayer.configure({ drm: { clearKeys: { [k1]: k2 } } });
        }

        await shakaPlayer.load("$safeUrl");

        // Try audio track selection (prefer Spanish)
        try {
            const tracks = shakaPlayer.getVariantTracks();
            const es = tracks.find(t => t.language === 'es' || (t.language && t.language.startsWith('es')));
            if (es) shakaPlayer.selectVariantTrack(es, true);
        } catch(_) {}

        await _attemptAutoplay(videoEl);
    } catch(e) {
        FlutterBridge.sendError('LOAD_ERR', e.message || 'Error al cargar stream');
    }

    FlutterBridge.startHealthSync();
    FlutterBridge.send('playerReady', { version: '6.0' });
}

document.addEventListener('DOMContentLoaded', initShaka);
</script>
</body>
</html>
''';

    _wvc.loadHtmlString(html);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 1. WebView ────────────────────────────────────────────
          Center(
            child: AspectRatio(
              aspectRatio: _getAspectRatio(),
              child: WebViewWidget(controller: _wvc),
            ),
          ),

          // ── 2. Controls ───────────────────────────────────────────
          Positioned.fill(
            child: CustomVideoControls(
              controller: _unified,
              channelName: widget.channelName,
              onFullScreenToggle: _toggleFullscreen,
              isFullScreen: _isFullscreen,
              aspectRatioLabel: _arType.label,
              onAspectRatioChange: _changeAspectRatio,
              onMuteToggle: _toggleMute,
              isMuted: _videoState.isMuted,
              currentServer: widget.currentServer,
              totalServers: widget.totalServers,
            ),
          ),

          // ── 3. Loading ────────────────────────────────────────────
          if (_videoState.isLoading || _videoState.isBuffering)
            VideoLoadingWidget(
              message: _videoState.isBuffering
                  ? (_videoState.stallDetected
                      ? 'Reconectando...'
                      : 'Cargando...')
                  : 'Cargando stream DRM...',
              isBuffering: _videoState.isBuffering,
              serverInfo: widget.totalServers > 1
                  ? '${widget.currentServer}/${widget.totalServers}'
                  : null,
            ),

          // ── 4. Error ──────────────────────────────────────────────
          if (_videoState.hasError && !_videoState.isLoading) _buildError(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withAlpha(20),
                  border:
                      Border.all(color: Colors.red.withAlpha(60), width: 1.5),
                ),
                child: const Icon(
                  Icons.signal_wifi_connected_no_internet_4_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No se pudo conectar',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _videoState.errorMessage ?? 'Error de reproducción DRM',
                style: GoogleFonts.dmSans(
                    color: Colors.white54, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (widget.totalServers > 1) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withAlpha(20), width: 0.5),
                  ),
                  child: Text(
                    'Servidor ${widget.currentServer}/${widget.totalServers}',
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _handleRefresh();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Theme.of(context).colorScheme.primary.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Reintentar',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stateMonitor?.cancel();
    _loadingFailsafe?.cancel();
    _loadTimeout?.cancel();
    _stateSub?.cancel();
    _unified.dispose();
    _videoState.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _wvc.loadRequest(Uri.parse('about:blank'));
    super.dispose();
  }
}
