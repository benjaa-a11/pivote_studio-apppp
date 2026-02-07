import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controller para comunicarse con ExoPlayer nativo en Android
class ExoPlayerController {
  final int viewId;
  late final MethodChannel _channel;
  
  // Stream controllers para eventos
  final _stateController = StreamController<PlayerState>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  // State
  PlayerState _state = PlayerState.idle;
  bool _isPlaying = false;
  bool _isDisposed = false;
  
  // Getters
  PlayerState get state => _state;
  bool get isPlaying => _isPlaying;
  Stream<PlayerState> get onStateChange => _stateController.stream;
  Stream<bool> get onPlayingChange => _playingController.stream;
  Stream<String> get onError => _errorController.stream;

  ExoPlayerController(this.viewId) {
    _channel = MethodChannel('exoplayer_$viewId');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Maneja llamadas desde el código nativo
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_isDisposed) return;

    switch (call.method) {
      case 'onStateChange':
        final stateStr = call.arguments as String;
        _state = _parseState(stateStr);
        _stateController.add(_state);
        break;

      case 'onPlayingChange':
        _isPlaying = call.arguments as bool;
        _playingController.add(_isPlaying);
        break;

      case 'onError':
        final error = call.arguments as Map;
        final message = error['message'] as String? ?? 'Unknown error';
        debugPrint('❌ ExoPlayer Error: $message');
        _errorController.add(message);
        break;
    }
  }

  PlayerState _parseState(String state) {
    switch (state) {
      case 'idle':
        return PlayerState.idle;
      case 'buffering':
        return PlayerState.buffering;
      case 'ready':
        return PlayerState.ready;
      case 'ended':
        return PlayerState.ended;
      default:
        return PlayerState.idle;
    }
  }

  /// Inicializa el reproductor con una URL y claves DRM opcionales
  Future<void> initialize(String url, {String? k1, String? k2}) async {
    if (_isDisposed) return;

    try {
      debugPrint('🎬 Inicializando ExoPlayer...');
      debugPrint('📺 URL: $url');
      if (k1 != null && k2 != null) {
        debugPrint('🔐 DRM: ClearKey');
        debugPrint('🔑 K1: $k1');
        debugPrint('🔑 K2: $k2');
      }

      await _channel.invokeMethod('initialize', {
        'url': url,
        if (k1 != null) 'k1': k1,
        if (k2 != null) 'k2': k2,
      });

      debugPrint('✅ ExoPlayer inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando ExoPlayer: $e');
      rethrow;
    }
  }

  /// Reproduce el video
  Future<void> play() async {
    if (_isDisposed) return;
    
    try {
      await _channel.invokeMethod('play');
    } catch (e) {
      debugPrint('❌ Error en play: $e');
    }
  }

  /// Pausa el video
  Future<void> pause() async {
    if (_isDisposed) return;
    
    try {
      await _channel.invokeMethod('pause');
    } catch (e) {
      debugPrint('❌ Error en pause: $e');
    }
  }

  /// Detiene el video
  Future<void> stop() async {
    if (_isDisposed) return;
    
    try {
      await _channel.invokeMethod('stop');
    } catch (e) {
      debugPrint('❌ Error en stop: $e');
    }
  }

  /// Establece el volumen (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    
    try {
      await _channel.invokeMethod('setVolume', {'volume': volume.clamp(0.0, 1.0)});
    } catch (e) {
      debugPrint('❌ Error en setVolume: $e');
    }
  }

  /// Obtiene la posición actual en milisegundos
  Future<int> getPosition() async {
    if (_isDisposed) return 0;
    
    try {
      final position = await _channel.invokeMethod<int>('getPosition');
      return position ?? 0;
    } catch (e) {
      debugPrint('❌ Error en getPosition: $e');
      return 0;
    }
  }

  /// Obtiene la duración total en milisegundos
  Future<int> getDuration() async {
    if (_isDisposed) return 0;
    
    try {
      final duration = await _channel.invokeMethod<int>('getDuration');
      return duration ?? 0;
    } catch (e) {
      debugPrint('❌ Error en getDuration: $e');
      return 0;
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    if (_isDisposed) return;
    
    _isDisposed = true;
    
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('❌ Error en dispose: $e');
    }

    await _stateController.close();
    await _playingController.close();
    await _errorController.close();
  }
}

/// Estados del reproductor
enum PlayerState {
  idle,
  buffering,
  ready,
  ended,
}