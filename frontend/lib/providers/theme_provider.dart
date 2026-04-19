import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题模式枚举
enum AppThemeMode {
  light,   // 浅色模式
  dark,    // 暗色模式
  system,  // 跟随系统
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  static const _key = 'app_theme_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'light':
        state = AppThemeMode.light;
        break;
      case 'dark':
        state = AppThemeMode.dark;
        break;
      case 'system':
      default:
        state = AppThemeMode.system;
        break;
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// 切换主题 (light -> dark -> system -> light)
  void cycle() {
    final next = switch (state) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
      AppThemeMode.system => AppThemeMode.light,
    };
    setTheme(next);
  }

  /// 获取Material ThemeMode
  ThemeMode get materialThemeMode => switch (state) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
  };

  /// 获取主题模式显示名称
  String get displayName => switch (state) {
    AppThemeMode.light => '浅色',
    AppThemeMode.dark => '深色',
    AppThemeMode.system => '跟随系统',
  };

  /// 获取主题模式图标
  IconData get icon => switch (state) {
    AppThemeMode.light => Icons.light_mode_rounded,
    AppThemeMode.dark => Icons.dark_mode_rounded,
    AppThemeMode.system => Icons.brightness_auto_rounded,
  };
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// 获取Material ThemeMode (用于MaterialApp)
final materialThemeModeProvider = Provider((ref) {
  return ref.read(themeProvider.notifier).materialThemeMode;
});

/// 判断当前是否为暗色模式 (考虑系统设置)
final isDarkModeProvider = Provider((ref) {
  final themeMode = ref.watch(themeProvider);
  if (themeMode == AppThemeMode.system) {
    // 跟随系统时，需要获取系统亮度
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }
  return themeMode == AppThemeMode.dark;
});
