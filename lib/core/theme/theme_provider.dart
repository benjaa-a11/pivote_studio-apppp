import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  int _textScaleStep = 3; // 1..5 (default 3 = 1.0x)
  bool _reduceAnimations = false;

  ThemeProvider() {
    _loadPreferences();
  }

  ThemeMode get themeMode => _themeMode;
  int get textScaleStep => _textScaleStep;
  bool get reduceAnimations => _reduceAnimations;

  double get textScaleFactor {
    switch (_textScaleStep) {
      case 1:
        return 0.90;
      case 2:
        return 0.95;
      case 3:
        return 1.00;
      case 4:
        return 1.06;
      case 5:
        return 1.12;
      default:
        return 1.00;
    }
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final platformBrightness =
          SchedulerBinding.instance.platformDispatcher.platformBrightness;
      return platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setTextScaleStep(int step) async {
    final clamped = step.clamp(1, 5);
    if (_textScaleStep == clamped) return;
    _textScaleStep = clamped;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool value) async {
    if (_reduceAnimations == value) return;
    _reduceAnimations = value;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString('theme_mode');
      if (modeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else if (modeStr == 'system') {
        _themeMode = ThemeMode.system;
      } else if (modeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        final legacyDark = prefs.getBool('isDarkMode') ?? true;
        _themeMode = legacyDark ? ThemeMode.dark : ThemeMode.light;
      }

      _textScaleStep = (prefs.getInt('text_scale_step') ?? 3).clamp(1, 5);
      _reduceAnimations = prefs.getBool('reduce_animations') ?? false;
      notifyListeners();
    } catch (e) {
      _themeMode = ThemeMode.dark;
      debugPrint('Error loading theme preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = _themeMode == ThemeMode.light
          ? 'light'
          : _themeMode == ThemeMode.system
              ? 'system'
              : 'dark';
      await prefs.setString('theme_mode', modeStr);
      await prefs.setBool('isDarkMode', isDarkMode);
      await prefs.setInt('text_scale_step', _textScaleStep);
      await prefs.setBool('reduce_animations', _reduceAnimations);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }
}
