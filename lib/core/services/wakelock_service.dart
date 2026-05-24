import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Global service to manage screen wakelock (keep screen on).
///
/// By default, the screen will never turn off while the app is active.
/// Users can toggle this off from Profile → Apariencia settings.
class WakelockService extends ChangeNotifier {
  static const String _prefKey = 'pivote_keep_screen_on';

  bool _keepScreenOn = true;

  WakelockService() {
    _init();
  }

  bool get keepScreenOn => _keepScreenOn;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to true — screen always on
      _keepScreenOn = prefs.getBool(_prefKey) ?? true;
      await _applyWakelock();
      notifyListeners();
    } catch (e) {
      // Fallback: enable wakelock by default
      _keepScreenOn = true;
      _applyWakelock();
      debugPrint('⚠️ WakelockService init error: $e');
    }
  }

  /// Toggle the keep-screen-on preference.
  Future<void> toggle() async {
    _keepScreenOn = !_keepScreenOn;
    await _applyWakelock();
    await _persist();
    notifyListeners();
  }

  /// Explicitly set the keep-screen-on preference.
  Future<void> setKeepScreenOn(bool value) async {
    if (_keepScreenOn == value) return;
    _keepScreenOn = value;
    await _applyWakelock();
    await _persist();
    notifyListeners();
  }

  Future<void> _applyWakelock() async {
    try {
      if (_keepScreenOn) {
        await WakelockPlus.enable();
        debugPrint('🔆 Wakelock ENABLED — screen will stay on');
      } else {
        await WakelockPlus.disable();
        debugPrint('🌙 Wakelock DISABLED — screen may turn off');
      }
    } catch (e) {
      debugPrint('⚠️ WakelockService apply error: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _keepScreenOn);
    } catch (e) {
      debugPrint('⚠️ WakelockService persist error: $e');
    }
  }

  @override
  void dispose() {
    // Don't disable wakelock on dispose — let the OS handle it
    super.dispose();
  }
}
