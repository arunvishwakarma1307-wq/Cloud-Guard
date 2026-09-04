import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _themeModeKey = 'cloud_guard_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  ThemeController() {
    ready = _loadThemeMode();
  }

  late final Future<void> ready;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;

  Future<void> _loadThemeMode() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedMode = preferences.getString(_themeModeKey);

      _themeMode = switch (storedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      _themeMode = ThemeMode.system;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeModeKey, _modeName(mode));
    } catch (_) {
      // Theme changes remain usable even if local persistence is unavailable.
    }
  }

  String _modeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}

final themeController = ThemeController();
