import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:pivote/features/video/presentation/widgets/video_loading_widget.dart';

// ════════════════════════════════════════════════════════════════════════════
// PIVO SHAKA PLAYER (MPD/DASH + ClearKey DRM) v6.0
// ════════════════════════════════════════════════════════════════════════════
// Dedicated WebView player injected with Shaka Player to decrypt `.mpd`
// and handle advanced CENC encryption that native libmpv might struggle with.
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

class _PivoShakaPlayerState extends State<PivoShakaPlayer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(PivoShakaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.k1 != widget.k1) {
      _isLoading = true;
      _hasError = false;
      _loadShakaHtml();
    }
  }

  void _initWebView() {
    final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _handleMessages,
      );

    _loadShakaHtml();
  }

  void _handleMessages(JavaScriptMessage message) {
    if (!mounted) return;
    try {
      final msg = jsonDecode(message.message);
      final type = msg['type'];

      if (type == 'playingStarted') {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      } else if (type == 'error') {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        widget.onAllServersFailed?.call();
      } else if (type == 'buffering') {
        final state = msg['state'];
        setState(() => _isLoading = state == 'waiting');
      }
    } catch (e) {
      debugPrint('WebView Parse Error: $e');
    }
  }

  void _loadShakaHtml() {
    // Generate JS configuration object equivalent to ConfiguracionCanales[id]
    final safeUrl = widget.url.replaceAll('"', '\\"');
    final safeK1 = widget.k1?.replaceAll('"', '\\"') ?? '';
    final safeK2 = widget.k2?.replaceAll('"', '\\"') ?? '';

    final html = '''
<!DOCTYPE html>
<html lang="es" class="no-js">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <title>Shaka Pro</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body {
            width: 100%; height: 100%;
            overflow: hidden;
            background: #000;
        }
        #player { width: 100%; height: 100%; position: relative; background: #000; }
        video {
            width: 100%; height: 100%;
            display: block; background: #000;
            object-fit: contain;
        }
        video::-webkit-media-controls { display: none !important; }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/shaka-player/4.7.0/shaka-player.compiled.min.js"></script>
</head>
<body>
    <div id="player">
        <video id="videoElement" autoplay playsinline muted></video>
    </div>

<script>
const FlutterBridge = (() => {
    function _send(type, extra = {}) {
        if (window.FlutterChannel) {
            window.FlutterChannel.postMessage(JSON.stringify({type, ...extra}));
        }
    }
    return {
        send: _send,
        sendError: (c, m) => _send('error', {code:c, message:m})
    };
})();

async function initShaka() {
    shaka.polyfill.installAll();
    if (!shaka.Player.isBrowserSupported()) {
        FlutterBridge.sendError('NOT_SUPPORTED', 'Navegador no soportado');
        return;
    }

    const video = document.getElementById('videoElement');
    const player = new shaka.Player(video);

    player.configure({
        streaming: { bufferingGoal: 8, rebufferingGoal: 2, retryParameters: { maxAttempts: 4 } },
        abr: { enabled: true }
    });

    video.addEventListener('playing', () => FlutterBridge.send('playingStarted'));
    video.addEventListener('waiting', () => FlutterBridge.send('buffering', {state: 'waiting'}));
    video.addEventListener('canplay', () => FlutterBridge.send('buffering', {state: 'ready'}));
    player.addEventListener('error', (e) => FlutterBridge.sendError('SHAKA_ERR', e.detail));

    try {
        const k1 = "$safeK1";
        const k2 = "$safeK2";
        if (k1 && k2) {
            player.configure({ drm: { clearKeys: { [k1]: k2 } } });
        }
        await player.load("$safeUrl");
        video.muted = false; // Intento unmute automático (WebView lo permite por política local)
        await video.play();
    } catch (e) {
        FlutterBridge.sendError('LOAD_ERR', e.message);
    }
}
document.addEventListener('DOMContentLoaded', initShaka);
</script>
</body>
</html>
''';

    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return const SizedBox(); // Fallback handles error UI over it

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          VideoLoadingWidget(
            isBuffering: true,
            serverInfo: '${widget.currentServer}/${widget.totalServers}',
            message: 'Cargando stream DRM...',
          ),
      ],
    );
  }
}
