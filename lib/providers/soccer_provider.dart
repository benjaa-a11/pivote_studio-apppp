import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/soccer_models.dart';
import '../services/soccer_service.dart';

class SoccerProvider extends ChangeNotifier {
  final SoccerService _soccerService = SoccerService();

  SoccerData? _soccerData;
  bool _isLoading = false;
  String? _error;
  Timer? _updateTimer;

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

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
