import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/system/blue_theme.dart';

class ThemeService {
  static const String _themeKey = 'app_theme';
  
  static const String system = 'system';
  static const String light = 'light';
  static const String dark = 'dark';
  static const String blue = 'blue';

  Future<void> saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? dark;
  }

  ThemeMode getThemeMode(String themeName) {
    switch (themeName) {
      case light:
        return ThemeMode.light;
      case dark:
        return ThemeMode.dark;
      case blue:
        return ThemeMode.dark;
      case system:
      default:
        return ThemeMode.system;
    }
  }

  ThemeData getThemeData(String themeName, BuildContext context) {
    switch (themeName) {
      case light:
        return ThemeData.light();
      case blue:
        return blueTheme;
      case dark:
      default:
        return ThemeData.dark();
    }
  }

  ThemeData getCurrentThemeData(BuildContext context) {
    final themeName = getThemeSync();
    return getThemeData(themeName, context);
  }

  String getThemeSync() {
    return dark;
  }
}