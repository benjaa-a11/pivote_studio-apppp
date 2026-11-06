import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════════════════
// PIVOTE MEDIA3 EXOPLAYER CONTROLLER & PLATFORM VIEW
// ════════════════════════════════════════════════════════════════════════════

/// Información de una pista (Video, Audio o Subtítulo)
class PlayerTrack {
  final int groupIndex;
  final int trackIndex;
  final bool isSelected;
  final bool isSupported;
  final int bitrate;
  final int width;
  final int height;
  final double frameRate;
  final int channels;
  final String language;
  final String label;
  final String mimeType;
  final String codecs;

  const PlayerTrack({
    required this.groupIndex,
    required this.trackIndex,
    this.isSelected = false,
    this.isSupported = true,
    this.bitrate = 0,
    this.width = 0,
    this.height = 0,
    this.frameRate = 0.0,
    this.channels = 0,
    this.language = '',
    this.label = '',
    this.mimeType = '',
    this.codecs = '',
  });

  String get id => '$groupIndex:$trackIndex';

  String get title {
    if (label.isNotEmpty) return label;
    if (height > 0) return '${height}p';
    if (language.isNotEmpty) return language.toUpperCase();
    return 'Pista $trackIndex';
  }

  factory PlayerTrack.fromMap(Map<dynamic, dynamic> map) {
    return PlayerTrack(
      groupIndex: (map['groupIndex'] as num?)?.toInt() ?? 0,
      trackIndex: (map['trackIndex'] as num?)?.toInt() ?? 0,
      isSelected: map['isSelected'] as bool? ?? false,
      isSupported: map['isSupported'] as bool? ?? true,
      bitrate: (map['bitrate'] as num?)?.toInt() ?? 0,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      frameRate: (map['frameRate'] as num?)?.toDouble() ?? 0.0,
      channels: (map['channels'] as num?)?.toInt() ?? 0,
      language: map['language'] as String? ?? '',
      label: map['label'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      codecs: map['codecs'] as String? ?? '',
    );
  }
}

/// Estado global de reproducción de Pivote Media3
class PivotePlayerController extends ChangeNotifier {
  MethodChannel? _methodChannel;
  EventChannel? _eventChannel;
  StreamSubscription? _eventSub;
  int? _viewId;
  int? get viewId => _viewId;
  bool _disposed = false;

  // Sesión actual (entero seguro para 32/64 bits en StandardMessageCodec)
  int _currentSessionId = 0;

  // Estados
  bool isPlaying = false;
  bool isBuffering = false;
  bool isLive = false;
  bool isSeekable = false;
  bool isMuted = false;
  double volume = 1.0;
  double playbackSpeed = 1.0;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  Duration buffered = Duration.zero;
  int videoWidth = 0;
  int videoHeight = 0;
  bool hasError = false;
  String? errorMessage;
  String? userMessage;
  String? errorCode;
  int httpStatus = -1;
  bool isReady = false;
  bool firstFrameRendered = false;
  String? streamFormat;
  bool videoUnsupported = false;

  // Tracks disponibles
  List<PlayerTrack> videoTracks = [];
  List<PlayerTrack> audioTracks = [];
  List<PlayerTrack> textTracks = [];

  // Pistas seleccionadas
  PlayerTrack? selectedAudioTrack;
  PlayerTrack? selectedSubtitleTrack;
  PlayerTrack? selectedVideoTrack;

  // Parámetros pendientes si se llama a prepare antes de que el PlatformView esté listo
  Map<String, dynamic>? _pendingPrepareParams;

  /// Vincula los canales nativos cuando se crea la PlatformView
  void attach(int viewId) {
    if (_disposed) return;

    // Si es la misma vista, evitar recrear innecesariamente
    if (_viewId == viewId && _methodChannel != null) {
      if (_pendingPrepareParams != null) {
        final params = _pendingPrepareParams!;
        _pendingPrepareParams = null;
        _methodChannel?.invokeMethod('prepare', params);
      }
      return;
    }

    _eventSub?.cancel();
    _viewId = viewId;
    _methodChannel = MethodChannel('pivote/player_methods_$viewId');
    _eventChannel = EventChannel('pivote/player_events_$viewId');

    // PRIMERO nos suscribimos al EventChannel para no perder ningún evento inicial
    _eventSub = _eventChannel!.receiveBroadcastStream().listen(
      _handleNativeEvent,
      onError: (error) {
        debugPrint('❌ PivotePlayer EventChannel error: $error');
        hasError = true;
        errorMessage = error.toString();
        userMessage = 'Error en el canal de eventos nativo';
        notifyListeners();
      },
    );

    // LUEGO enviamos el prepare pendiente
    if (_pendingPrepareParams != null) {
      final params = _pendingPrepareParams!;
      _pendingPrepareParams = null;
      _methodChannel?.invokeMethod('prepare', params);
    }
  }

  void _handleNativeEvent(dynamic raw) {
    if (_disposed || raw is! Map) return;
    final map = raw;
    final eventSession = (map['sessionId'] as num?)?.toInt() ?? 0;

    // Descartar eventos de sesiones anteriores
    if (eventSession != 0 && _currentSessionId != 0 && eventSession != _currentSessionId) {
      return;
    }

    final event = map['event'] as String? ?? '';

    switch (event) {
      case 'ready':
        isReady = true;
        isBuffering = false;
        hasError = false;
        errorMessage = null;
        userMessage = null;
        isLive = map['isLive'] as bool? ?? false;
        isSeekable = map['isSeekable'] as bool? ?? false;
        streamFormat = map['format'] as String?;
        final durMs = (map['durationMs'] as num?)?.toInt() ?? -1;
        duration = durMs > 0 ? Duration(milliseconds: durMs) : Duration.zero;
        videoWidth = (map['videoWidth'] as num?)?.toInt() ?? videoWidth;
        videoHeight = (map['videoHeight'] as num?)?.toInt() ?? videoHeight;
        notifyListeners();
        break;

      case 'firstFrame':
        firstFrameRendered = true;
        isReady = true;
        isBuffering = false;
        hasError = false;
        notifyListeners();
        break;

      case 'videoSize':
        final w = (map['videoWidth'] as num?)?.toInt() ?? 0;
        final h = (map['videoHeight'] as num?)?.toInt() ?? 0;
        if (w > 0 && h > 0) {
          videoWidth = w;
          videoHeight = h;
          isReady = true;
          isBuffering = false;
          notifyListeners();
        }
        break;

      case 'stateChanged':
        final state = map['playbackState'] as String? ?? '';
        isPlaying = map['isPlaying'] as bool? ?? false;
        isBuffering = state == 'buffering';
        if (state == 'ready' || isPlaying) {
          isReady = true;
          hasError = false;
          if (isPlaying) {
            isBuffering = false;
          }
        }
        notifyListeners();
        break;

      case 'position':
        final posMs = (map['positionMs'] as num?)?.toInt() ?? 0;
        final bufMs = (map['bufferedMs'] as num?)?.toInt() ?? 0;
        final durMs = (map['durationMs'] as num?)?.toInt() ?? -1;
        position = Duration(milliseconds: posMs);
        buffered = Duration(milliseconds: bufMs);
        if (durMs > 0 && !isLive) {
          duration = Duration(milliseconds: durMs);
        }
        if (isPlaying && !isReady) {
          isReady = true;
          isBuffering = false;
        }
        notifyListeners();
        break;

      case 'tracksChanged':
        final rawVideos = map['videoTracks'] as List? ?? [];
        final rawAudios = map['audioTracks'] as List? ?? [];
        final rawTexts = map['textTracks'] as List? ?? [];
        videoUnsupported = map['videoUnsupported'] as bool? ?? false;

        videoTracks = rawVideos.map((e) => PlayerTrack.fromMap(e as Map)).toList();
        audioTracks = rawAudios.map((e) => PlayerTrack.fromMap(e as Map)).toList();
        textTracks = rawTexts.map((e) => PlayerTrack.fromMap(e as Map)).toList();

        selectedAudioTrack = audioTracks.where((t) => t.isSelected).firstOrNull;
        selectedSubtitleTrack = textTracks.where((t) => t.isSelected).firstOrNull;
        selectedVideoTrack = videoTracks.where((t) => t.isSelected).firstOrNull;
        notifyListeners();
        break;

      case 'error':
        hasError = true;
        isBuffering = false;
        errorCode = map['errorCode'] as String?;
        errorMessage = map['message'] as String? ?? 'Error de reproducción';
        userMessage = map['userMessage'] as String? ?? errorMessage;
        httpStatus = (map['httpStatus'] as num?)?.toInt() ?? -1;
        notifyListeners();
        break;

      case 'retrying':
        isBuffering = true;
        final reason = map['reason'] as String?;
        debugPrint('🔄 Reintento automático del reproductor: $reason');
        notifyListeners();
        break;

      case 'ended':
        isPlaying = false;
        isBuffering = false;
        notifyListeners();
        break;
    }
  }

  /// Carga y prepara un canal o URL en Media3 ExoPlayer
  Future<void> prepare({
    required String url,
    String? type,
    String? channelName,
    String? icono,
    Map<String, String>? headers,
    Map<String, String>? clearkeys,
    String? k1,
    String? k2,
    String? drmType,
    String? drmLicenseUri,
    String? widevineLicenseUrl,
    Map<String, String>? widevineLicenseHeaders,
    bool forceL3 = false,
  }) async {
    if (_disposed) return;

    _currentSessionId = (_currentSessionId + 1) & 0x3FFFFFFF;
    if (_currentSessionId == 0) _currentSessionId = 1;

    hasError = false;
    errorMessage = null;
    userMessage = null;
    errorCode = null;
    isReady = false;
    firstFrameRendered = false;
    isBuffering = true;
    videoUnsupported = false;
    notifyListeners();

    final params = <String, dynamic>{
      'sessionId': _currentSessionId,
      'original_url': url,
      'url': url,
      'name': channelName ?? '',
      'type': type,
      'icono': icono,
      'headers': headers ?? {},
      'force_l3': forceL3,
    };

    if (drmLicenseUri != null && drmLicenseUri.isNotEmpty) {
      params['drm_license_uri'] = drmLicenseUri;
    }

    if (drmType != null && drmType.toUpperCase() == 'WIDEVINE') {
      params['drm'] = {
        'type': 'WIDEVINE',
        'licenseUrl': widevineLicenseUrl ?? drmLicenseUri,
        'licenseHeaders': widevineLicenseHeaders ?? {},
        'forceL3': forceL3,
      };
    } else if (clearkeys != null && clearkeys.isNotEmpty) {
      params['clearkeys'] = clearkeys;
      params['drm'] = {
        'type': 'CLEARKEY',
        'clearKeys': clearkeys,
      };
    } else if (k1 != null && k2 != null && k1.isNotEmpty && k2.isNotEmpty) {
      params['k1'] = k1;
      params['k2'] = k2;
      params['drm'] = {
        'type': 'CLEARKEY',
        'clearKeys': {k1: k2},
      };
    }

    if (_methodChannel != null) {
      try {
        await _methodChannel!.invokeMethod('prepare', params);
      } catch (e) {
        debugPrint('Error invoking prepare on native player: $e');
      }
    } else {
      _pendingPrepareParams = params;
    }
  }

  Future<void> play() async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('play');
      isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in play: $e');
    }
  }

  Future<void> pause() async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('pause');
      isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error in pause: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seekTo(Duration targetPosition) async {
    if (_disposed || _methodChannel == null) return;
    try {
      position = targetPosition;
      notifyListeners();
      await _methodChannel!.invokeMethod('seekTo', {
        'positionMs': targetPosition.inMilliseconds,
      });
    } catch (e) {
      debugPrint('Error in seekTo: $e');
    }
  }

  Future<void> seekToLiveEdge() async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('seekToLiveEdge');
    } catch (e) {
      debugPrint('Error in seekToLiveEdge: $e');
    }
  }

  Future<void> setVolume(double newVolume) async {
    if (_disposed || _methodChannel == null) return;
    try {
      volume = newVolume.clamp(0.0, 1.0);
      isMuted = volume == 0.0;
      notifyListeners();
      await _methodChannel!.invokeMethod('setVolume', {'volume': volume});
    } catch (e) {
      debugPrint('Error in setVolume: $e');
    }
  }

  Future<void> toggleMute() async {
    if (isMuted) {
      await setVolume(1.0);
    } else {
      await setVolume(0.0);
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_disposed || _methodChannel == null) return;
    try {
      playbackSpeed = speed.clamp(0.25, 2.0);
      notifyListeners();
      await _methodChannel!.invokeMethod('setPlaybackSpeed', {'speed': playbackSpeed});
    } catch (e) {
      debugPrint('Error in setPlaybackSpeed: $e');
    }
  }

  Future<void> setResizeMode(String mode) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('setResizeMode', {'mode': mode});
    } catch (e) {
      debugPrint('Error in setResizeMode: $e');
    }
  }

  Future<void> setTrack({
    required String trackType,
    required int groupIndex,
    required int trackIndex,
  }) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('setTrack', {
        'trackType': trackType,
        'groupIndex': groupIndex,
        'trackIndex': trackIndex,
      });
    } catch (e) {
      debugPrint('Error in setTrack: $e');
    }
  }

  Future<void> selectAudioTrack(PlayerTrack track) async {
    selectedAudioTrack = track;
    notifyListeners();
    await setTrack(
      trackType: 'audio',
      groupIndex: track.groupIndex,
      trackIndex: track.trackIndex,
    );
  }

  Future<void> selectSubtitleTrack(PlayerTrack? track) async {
    selectedSubtitleTrack = track;
    notifyListeners();
    if (track == null) {
      await setTrack(trackType: 'text', groupIndex: -1, trackIndex: -1);
    } else {
      await setTrack(
        trackType: 'text',
        groupIndex: track.groupIndex,
        trackIndex: track.trackIndex,
      );
    }
  }

  Future<void> setPreferredQuality({int maxHeight = -1, int maxBitrate = -1}) async {
    if (_disposed || _methodChannel == null) return;
    try {
      await _methodChannel!.invokeMethod('setPreferredVideoQuality', {
        'maxHeight': maxHeight,
        'maxBitrate': maxBitrate,
      });
    } catch (e) {
      debugPrint('Error in setPreferredQuality: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSub?.cancel();
    _methodChannel?.invokeMethod('release');
    _methodChannel = null;
    _eventChannel = null;
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PLATFORM VIEW WIDGET (AndroidView)
// ════════════════════════════════════════════════════════════════════════════

class PivotePlayerView extends StatefulWidget {
  final PivotePlayerController controller;
  final bool useTextureView;

  const PivotePlayerView({
    super.key,
    required this.controller,
    this.useTextureView = true,
  });

  @override
  State<PivotePlayerView> createState() => _PivotePlayerViewState();
}

class _PivotePlayerViewState extends State<PivotePlayerView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Media3 ExoPlayer es exclusivo para Android',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return AndroidView(
      viewType: 'pivote-exoplayer',
      onPlatformViewCreated: (viewId) {
        widget.controller.attach(viewId);
      },
      creationParams: {
        'useTextureView': widget.useTextureView,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ALIASES PARA COMPATIBILIDAD CON CÓDIGO EXISTENTE
// ════════════════════════════════════════════════════════════════════════════
typedef ExoPlayerController = PivotePlayerController;
typedef ExoPlayerWidget = PivotePlayerView;
typedef UnifiedVideoController = PivotePlayerController;
