import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/preferences_service.dart';
import '../config/theme.dart';

class ThemeProvider with ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  
  bool _isDark = false;
  bool get isDark => _isDark;

  bool _isInitialized = false;

  ThemeProvider() {
    // Delay initialization to ensure native channels are ready
    Future.microtask(() => _loadTheme());
  }

  Future<void> _loadTheme() async {
    if (_isInitialized) return;
    
    try {
      // Add delay to ensure native channels are ready
      await Future.delayed(const Duration(milliseconds: 500));
      final theme = await _preferencesService.getTheme();
      _isDark = theme == 'dark';
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // Use default theme if loading fails
      _isDark = false;
      _isInitialized = true;
      notifyListeners();
      debugPrint('Error loading theme: $e');
    }
  }

  ThemeData get theme => _isDark ? AppTheme.getDarkTheme() : AppTheme.getLightTheme();

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    await _preferencesService.setTheme(_isDark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _isDark = isDark;
    await _preferencesService.setTheme(isDark ? 'dark' : 'light');
    notifyListeners();
  }
}

