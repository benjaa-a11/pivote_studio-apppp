import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════════════════
// ExoPlayerWidget — Flutter wrapper for native Android ExoPlayer
// ════════════════════════════════════════════════════════════════════════════
//
// Embeds a native ExoPlayer via PlatformView (AndroidView).
// Communicates via MethodChannel for control + EventChannel for state.
//
// Lifecycle:
//   onCreate → initialize(url, k1, k2) → playing → dispose
//
// ════════════════════════════════════════════════════════════════════════════

/// Callback types for ExoPlayer events
typedef ExoPlayerEventCallback = void Function(ExoPlayerEvent event);

/// Event from the native ExoPlayer
class ExoPlayerEvent {
  final String type;
  final bool isPlaying;
  final bool isBuffering;
  final double volume;
  final int? errorCode;
  final String? errorMessage;
  final String? errorType;
  final int currentPosition;
  final int duration;
  final int bufferedPosition;

  const ExoPlayerEvent({
    required this.type,
    this.isPlaying = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.errorCode,
    this.errorMessage,
    this.errorType,
    this.currentPosition = 0,
    this.duration = 0,
    this.bufferedPosition = 0,
  });

  factory ExoPlayerEvent.fromMap(Map<dynamic, dynamic> map) {
    return ExoPlayerEvent(
      type: map['type'] as String? ?? 'unknown',
      isPlaying: map['isPlaying'] as bool? ?? false,
      isBuffering: map['isBuffering'] as bool? ?? false,
      volume: (map['volume'] as num?)?.toDouble() ?? 1.0,
      errorCode: map['code'] as int?,
      errorMessage: map['message'] as String?,
      errorType: map['errorType'] as String?,
      currentPosition: (map['currentPosition'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      bufferedPosition: (map['bufferedPosition'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasError => type == 'error';
  bool get isReady => type == 'ready';
}

/// Controller for the native ExoPlayer
class ExoPlayerController {
  MethodChannel? _methodChannel;
  EventChannel? _eventChannel;
  StreamSubscription? _eventSub;
  final List<ExoPlayerEventCallback> _listeners = [];
  bool _disposed = false;

  // Current state
  bool isPlaying = false;
  bool isBuffering = false;
  bool isMuted = false;
  double volume = 1.0;
  bool hasError = false;
  String? errorMessage;
  bool isInitialized = false;

  /// Called by the widget when the platform view is created
  void attach(int viewId) {
    _methodChannel = MethodChannel('pivote/exoplayer_$viewId');
    _eventChannel = EventChannel('pivote/exoplayer_events_$viewId');

    _eventSub = _eventChannel!.receiveBroadcastStream().listen(
      (dynamic event) {
        if (_disposed || event is! Map) return;
        final e = ExoPlayerEvent.fromMap(event);
        _updateState(e);
        for (final cb in List.of(_listeners)) {
          cb(e);
        }
      },
      onError: (dynamic error) {
        debugPrint('❌ ExoPlayer EventChannel error: $error');
      },
    );
  }

  void _updateState(ExoPlayerEvent e) {
    isPlaying = e.isPlaying;
    isBuffering = e.isBuffering;
    volume = e.volume;

    switch (e.type) {
      case 'ready':
      case 'playing':
        isInitialized = true;
        hasError = false;
        errorMessage = null;
        break;
      case 'error':
        hasError = true;
        errorMessage = e.errorMessage;
        break;
      case 'buffering':
        isBuffering = true;
        break;
    }
  }

  /// Initialize with MPD stream + optional ClearKey DRM (multi-key or legacy)
  Future<void> initialize({
    required String url,
    String? name,
    String? type,
    String? drmLicenseUri,
    String? icono,
    String? k1,
    String? k2,
    Map<String, String>? clearkeys,
    Map<String, String>? headers,
  }) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('initialize', {
        'url': url,
        'original_url': url,
        if (name != null && name.isNotEmpty) 'name': name,
        if (type != null && type.isNotEmpty) 'type': type,
        if (drmLicenseUri != null && drmLicenseUri.isNotEmpty)
          'drm_license_uri': drmLicenseUri,
        if (icono != null && icono.isNotEmpty) 'icono': icono,
        if (k1 != null && k1.isNotEmpty) 'k1': k1,
        if (k2 != null && k2.isNotEmpty) 'k2': k2,
        if (clearkeys != null && clearkeys.isNotEmpty) 'clearkeys': clearkeys,
        if (headers != null) 'headers': headers,
      });
    } catch (e) {
      debugPrint('❌ ExoPlayer initialize: $e');
    }
  }

  Future<void> play() async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('play');
    } catch (_) {}
  }

  Future<void> pause() async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('pause');
    } catch (_) {}
  }

  Future<void> setVolume(double v) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('setVolume', {'volume': v});
      volume = v;
      isMuted = v == 0;
    } catch (_) {}
  }

  Future<void> setMuted(bool muted) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('setMuted', {'muted': muted});
      isMuted = muted;
    } catch (_) {}
  }

  Future<void> seekTo(Duration position) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!
          .invokeMethod('seekTo', {'position': position.inMilliseconds});
    } catch (_) {}
  }

  void addListener(ExoPlayerEventCallback cb) => _listeners.add(cb);
  void removeListener(ExoPlayerEventCallback cb) => _listeners.remove(cb);

  Future<void> dispose() async {
    _disposed = true;
    await _eventSub?.cancel();
    _listeners.clear();
    if (_methodChannel != null) {
      try {
        await _methodChannel!.invokeMethod('dispose');
      } catch (_) {}
    }
  }
}

/// Widget that renders the native ExoPlayer via AndroidView
class ExoPlayerWidget extends StatefulWidget {
  final String url;
  final String? name;
  final String? type;
  final String? drmLicenseUri;
  final String? icono;
  final String? k1;
  final String? k2;
  final Map<String, String>? clearkeys; // Multi-key ClearKey DRM
  final Map<String, String>? headers;
  final ExoPlayerController controller;
  final VoidCallback? onReady;
  final VoidCallback? onError;

  const ExoPlayerWidget({
    super.key,
    required this.url,
    this.name,
    this.type,
    this.drmLicenseUri,
    this.icono,
    this.k1,
    this.k2,
    this.clearkeys,
    this.headers,
    required this.controller,
    this.onReady,
    this.onError,
  });

  @override
  State<ExoPlayerWidget> createState() => _ExoPlayerWidgetState();
}

class _ExoPlayerWidgetState extends State<ExoPlayerWidget> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: 'pivote-exoplayer',
      creationParams: <String, dynamic>{
        'url': widget.url,
        'original_url': widget.url,
        if (widget.name != null && widget.name!.isNotEmpty) 'name': widget.name,
        if (widget.type != null && widget.type!.isNotEmpty) 'type': widget.type,
        if (widget.drmLicenseUri != null && widget.drmLicenseUri!.isNotEmpty)
          'drm_license_uri': widget.drmLicenseUri,
        if (widget.icono != null && widget.icono!.isNotEmpty)
          'icono': widget.icono,
        if (widget.k1 != null) 'k1': widget.k1,
        if (widget.k2 != null) 'k2': widget.k2,
        if (widget.clearkeys != null && widget.clearkeys!.isNotEmpty)
          'clearkeys': widget.clearkeys,
        if (widget.headers != null && widget.headers!.isNotEmpty)
          'headers': widget.headers,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  void _onPlatformViewCreated(int viewId) {
    if (_initialized) return;
    _initialized = true;

    widget.controller.attach(viewId);

    // Listen for ready/error events
    widget.controller.addListener((event) {
      if (event.isReady && widget.onReady != null) {
        widget.onReady!();
      }
      if (event.hasError && widget.onError != null) {
        widget.onError!();
      }
    });
  }
}
