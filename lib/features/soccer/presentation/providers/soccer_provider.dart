import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pivote/features/soccer/data/models/soccer_models.dart';
import 'package:pivote/features/soccer/data/services/soccer_service.dart';
import 'package:pivote/core/services/image_cache_helper.dart';

class SoccerProvider extends ChangeNotifier {
  final SoccerService _soccerService = SoccerService();

  SoccerData? _soccerData;
  bool _isLoading = false;
  String? _error;
  Timer? _updateTimer;
  DateTime? _lastFetchedAt;

  SoccerData? get soccerData => _soccerData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SoccerProvider() {
    fetchData();
    _startAutoUpdate();
  }

  Future<void> fetchData({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final newData = await _soccerService.fetchLiveSoccerData();
      _soccerData = newData;
      _isLoading = false;
      _error = null;
      _lastFetchedAt = DateTime.now();

      // Pre-cargar logos de equipos y ligas en background (solo la primera vez)
      if (!silent) {
        _warmUpSoccerLogos(newData);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
    } finally {
      notifyListeners();
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 16), (timer) {
      fetchData(silent: true);
    });
  }

  void retry() {
    fetchData();
    _startAutoUpdate();
  }

  void refreshIfStale() {
    if (_lastFetchedAt == null) {
      fetchData(silent: true);
      return;
    }
    
    final difference = DateTime.now().difference(_lastFetchedAt!);
    if (difference.inSeconds > 60) {
      debugPrint('🔄 SoccerProvider: Datos desactualizados (${difference.inSeconds}s), refrescando...');
      fetchData(silent: true);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Pre-carga logos de equipos y ligas de fútbol en background
  void _warmUpSoccerLogos(SoccerData data) {
    try {
      final logoUrls = <String>{};

      // Logos de equipos
      for (final team in data.teams) {
        final url = team.logoUrl;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          logoUrls.add(url);
        }
      }

      // Logos de ligas/torneos
      for (final league in data.leagues) {
        final url = league.logoUrl;
        if (url != null && url.isNotEmpty && url.startsWith('http')) {
          logoUrls.add(url);
        }
      }

      if (logoUrls.isNotEmpty) {
        debugPrint('⚽ Pre-cargando ${logoUrls.length} logos de fútbol...');
        ImageCacheHelper.warmUpCache(logoUrls.toList(), isLogos: true);
      }
    } catch (e) {
      debugPrint('Error in soccer logo warm-up: $e');
    }
  }
}
