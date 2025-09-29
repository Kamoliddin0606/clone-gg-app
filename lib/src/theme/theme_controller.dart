import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// App-wide theme controller using ValueNotifier (no extra packages).
/// Persisting is optional (see _persist callbacks).
class ThemeController {
  ThemeController._(ThemeMode initial) : mode = ValueNotifier<ThemeMode>(initial);
  static final ThemeController I = ThemeController._(ThemeMode.system);

  static const _kThemeKey = 'theme_mode';
  /// Current theme mode (listen with ValueListenableBuilder).
  final ValueNotifier<ThemeMode> mode;


  /// Set explicit light/dark.
  void set(ThemeMode m) {
    if (mode.value == m) return;
    mode.value = m;
    _persist(m);
  }


  /// (Optional) Persist using your SharedPreferencesService via service locator
  // Saqlash: light|dark|system
  void _persist(ThemeMode m) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeKey, m.name);
    } catch (_) {
      // xatoni jim o‘tamiz
    }
  }


  /// (Optional) Restore at app start (call once in main())
  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_kThemeKey);
      if (s == null) return;
      switch (s) {
        case 'light':
          mode.value = ThemeMode.light;
          break;
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        default:
          mode.value = ThemeMode.system;
      }
    } catch (_) {
      // jim o‘tamiz
    }
  }
}