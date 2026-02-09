import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Controller optimizado para ExoPlayer IPTV M3U8/HLS
class ExoPlayerController {
  final int viewId;
  late final MethodChannel _channel;
  
  // Stream controllers para eventos
  final _stateController = StreamController<PlayerState>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _stalledController = StreamController<void>.broadcast();
  
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
  Stream<void> get onStreamStalled => _stalledController.stream;

  ExoPlayerController(this.viewId) {
    _channel = MethodChannel('exoplayer_$viewId');
    _channel.setMethodCallHandler(_handleMethodCall);
    debugPrint('🎮 ExoPlayerController IPTV created for view $viewId');
  }

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
        final message = error['message'] as String? ?? 'Error desconocido';
        _errorController.add(message);
        break;

      case 'onStreamStalled':
        debugPrint('🚨 Stream trabado > 15s');
        _stalledController.add(null);
        break;
    }
  }

  PlayerState _parseState(String state) {
    switch (state.toLowerCase()) {
      case 'idle': return PlayerState.idle;
      case 'buffering': return PlayerState.buffering;
      case 'ready': return PlayerState.ready;
      case 'ended': return PlayerState.ended;
      default: return PlayerState.idle;
    }
  }

  /// Inicializa el reproductor con URL M3U8
  Future<void> initialize(String url) async {
    if (_isDisposed) return;
    await _channel.invokeMethod('initialize', {'url': url});
  }

  Future<void> play() async {
    if (_isDisposed) return;
    await _channel.invokeMethod('play');
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await _channel.invokeMethod('pause');
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await _channel.invokeMethod('stop');
  }

  Future<void> setVolume(double volume) async {
    if (_isDisposed) return;
    await _channel.invokeMethod('setVolume', {'volume': volume.clamp(0.0, 1.0)});
  }

  Future<int> getPosition() async {
    if (_isDisposed) return 0;
    final position = await _channel.invokeMethod<int>('getPosition');
    return position ?? 0;
  }

  Future<int> getDuration() async {
    if (_isDisposed) return 0;
    final duration = await _channel.invokeMethod<int>('getDuration');
    return duration ?? 0;
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    
    try {
      await _channel.invokeMethod('dispose');
    } catch (e) {
      debugPrint('Error disposing: $e');
    }

    await _stateController.close();
    await _playingController.close();
    await _errorController.close();
    await _stalledController.close();
  }
}

enum PlayerState {
  idle,
  buffering,
  ready,
  ended,
}