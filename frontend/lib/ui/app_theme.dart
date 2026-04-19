import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Linear Design System v3.0
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 设计理念：极简 · 清晰 · 专业
///
/// 核心原则：
/// 1. 极简主义 - 大量留白，干净的界面
/// 2. 微妙边框 - 使用细边框而非阴影
/// 3. 克制色彩 - 主色用于强调，大量使用灰色系
/// 4. 清晰层次 - 通过背景色差异区分
/// 5. 精致交互 - 微妙的hover效果
/// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // Linear Light Theme
  // ══════════════════════════════════════════════════════════════════════════

  /// 主色 - Linear紫 (用于强调、链接、按钮)
  static const Color primary = Color(0xFF5E6AD2);
  static const Color primaryHover = Color(0xFF4F5BC3);
  static const Color primaryLight = Color(0xFFEEF0FD);

  /// 文字色 - 灰度系统
  static const Color ink = Color(0xFF1A1A1A);           // 主文字
  static const Color inkSecondary = Color(0xFF5C5C5C);  // 次要文字
  static const Color inkTertiary = Color(0xFF8A8A8A);   // 三级文字
  static const Color inkMuted = Color(0xFFB3B3B3);      // 弱化文字

  /// 背景色 - 层次系统
  static const Color canvas = Color(0xFFFFFFFF);        // 画布背景
  static const Color surface = Color(0xFFFFFFFF);       // 卡片表面
  static const Color surfaceHover = Color(0xFFFAFAFA);  // 悬停背景
  static const Color surfaceActive = Color(0xFFF5F5F5); // 激活背景
  static const Color surfaceMuted = Color(0xFFF0F0F0);  // 弱化背景

  /// 边框色
  static const Color border = Color(0xFFE5E5E5);        // 默认边框
  static const Color borderHover = Color(0xFFD4D4D4);   // 悬停边框
  static const Color borderFocus = Color(0xFF5E6AD2);   // 聚焦边框

  /// 语义色
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // ══════════════════════════════════════════════════════════════════════════
  // Linear Dark Theme
  // ══════════════════════════════════════════════════════════════════════════

  static const Color darkPrimary = Color(0xFF7B83EB);
  static const Color darkPrimaryHover = Color(0xFF8B93F0);
  static const Color darkPrimaryLight = Color(0xFF2A2F4A);

  static const Color darkInk = Color(0xFFF5F5F5);
  static const Color darkInkSecondary = Color(0xFFB3B3B3);
  static const Color darkInkTertiary = Color(0xFF8A8A8A);
  static const Color darkInkMuted = Color(0xFF666666);

  static const Color darkCanvas = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkSurfaceHover = Color(0xFF1A1A1A);
  static const Color darkSurfaceActive = Color(0xFF242424);
  static const Color darkSurfaceMuted = Color(0xFF2A2A2A);

  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkBorderHover = Color(0xFF3A3A3A);
  static const Color darkBorderFocus = Color(0xFF7B83EB);

  // ══════════════════════════════════════════════════════════════════════════
  // 四象限色彩 (Linear风格 - 更柔和)
  // ══════════════════════════════════════════════════════════════════════════

  static const Color urgentImportant = Color(0xFFE53935);     // 红色
  static const Color importantNotUrgent = Color(0xFF5E6AD2);  // 主色
  static const Color urgentNotImportant = Color(0xFFFF9800);  // 橙色
  static const Color notUrgentNotImportant = Color(0xFF8A8A8A); // 灰色

  // ══════════════════════════════════════════════════════════════════════════
  // 设计令牌
  // ══════════════════════════════════════════════════════════════════════════

  /// 圆角 - Linear使用较小的圆角
  static const double radiusXs = 4;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;
  static const double radiusFull = 999;

  /// 间距 - 4px基础单位
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;

  /// 动效
  static const Duration durationFast = Duration(milliseconds: 100);
  static const Duration durationNormal = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 300);

  // ══════════════════════════════════════════════════════════════════════════
  // 向后兼容
  // ══════════════════════════════════════════════════════════════════════════

  static const Color textMuted = inkTertiary;
  static const Color paper = canvas;
  static const Color blush = primary;
  static const Color softBlue = primaryLight;
  static const Color softGreen = successLight;
  static const Color softAmber = warningLight;
  static const Color softRose = dangerLight;
  static const Color softViolet = primaryLight;
  static const Color softPrimary = primaryLight;
  static const Color softSuccess = successLight;
  static const Color softWarning = warningLight;
  static const Color softDanger = dangerLight;
  static const Color pageBgTop = canvas;
  static const Color pageBgMid = surfaceHover;
  static const Color pageBgBottom = surfaceActive;
  static const Color panel = surface;
  static const Color panelBorder = border;
  static const Color heroStart = Color(0xFF5E6AD2);
  static const Color heroMid = Color(0xFF7B83EB);
  static const Color heroEnd = Color(0xFF9B9FF5);
  static const Color errorBg = dangerLight;
  static const Color errorBorder = danger;
  static const Color warnBg = warningLight;
  static const Color warnBorder = warning;
  static const Color neutral = inkTertiary;
  static const Color neutralStrong = inkSecondary;
  static const Color accent = urgentImportant;
  static const Color successDark = success;
  static const Color warningDark = warning;
  static const Color dangerDark = danger;
  static const Color primaryDark = darkPrimary;
  static const Color heroGradient = primary;
  static const Color surfaceAlt = surfaceMuted;

  // 动效兼容
  static const Duration motionFast = durationFast;
  static const Duration motionMedium = durationNormal;
  static const Duration motionSlow = durationSlow;

  // 阴影 - Linear风格几乎不用阴影，使用边框代替
  static List<BoxShadow> shadowSm = [];
  static List<BoxShadow> shadowMd = [];
  static List<BoxShadow> shadowLg = [];

  // ══════════════════════════════════════════════════════════════════════════
  // 主题构建
  // ══════════════════════════════════════════════════════════════════════════

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primary,
      surface: canvas,
      surfaceContainerHighest: surfaceHover,
      error: danger,
      brightness: Brightness.light,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(primary),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(inkSecondary),
          iconSize: const WidgetStatePropertyAll(20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(ink),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm))),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: inkSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusSm))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return surfaceMuted;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusSm))),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: darkPrimary,
      primary: darkPrimary,
      secondary: darkPrimary,
      surface: darkCanvas,
      surfaceContainerHighest: darkSurfaceHover,
      error: danger,
      brightness: Brightness.dark,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: darkCanvas,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const TextStyle(
          color: darkInk,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: const TextStyle(fontSize: 12, color: darkInk, fontWeight: FontWeight.w500),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(darkPrimary),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(darkInkSecondary),
          iconSize: const WidgetStatePropertyAll(20),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(darkInk),
          side: const WidgetStatePropertyAll(BorderSide(color: darkBorder)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm))),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: darkInkSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusSm))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPrimary;
          return darkSurfaceMuted;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusSm))),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
    );
  }
}
