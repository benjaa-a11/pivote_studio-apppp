import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  
  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ensure dark mode is always default, even if no preference is saved
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      notifyListeners();
    } catch (e) {
      // If there's any error loading preferences, default to dark mode
      _isDarkMode = true;
      debugPrint('Error loading theme, defaulting to dark mode: $e');
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
}