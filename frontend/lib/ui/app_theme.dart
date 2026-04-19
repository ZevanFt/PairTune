import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Priority First 设计系统 v2.0
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 设计理念：温暖专注 · 清晰高效 · 活力平衡
///
/// 核心价值观：
/// 1. 温暖专注 - 使用温暖的色调，让用户感到舒适和专注
/// 2. 清晰高效 - 信息层次分明，操作直观高效
/// 3. 活力平衡 - 色彩有活力但不刺眼，保持视觉平衡
///
/// 色彩策略：
/// - 主色：深青色 (#0D7377) - 稳重、专业、可信赖
/// - 强调色：珊瑚橙 (#FF6B6B) - 温暖、活力、行动感
/// - 成功色：薄荷绿 (#4ECDC4) - 清新、完成、积极
/// - 背景色：暖白 (#FAFAF8) - 温暖、舒适、不刺眼
/// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // 核心色板 - Core Palette
  // ══════════════════════════════════════════════════════════════════════════

  /// 主色 - 深青色：稳重、专业、可信赖
  /// 用于：主要按钮、重要图标、选中状态
  static const Color primary = Color(0xFF0D7377);
  static const Color primaryLight = Color(0xFF14A3A8);
  static const Color primaryDark = Color(0xFF095456);

  /// 强调色 - 珊瑚橙：温暖、活力、行动感
  /// 用于：重要提醒、紧急任务、CTA按钮
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8585);
  static const Color accentDark = Color(0xFFE55555);

  /// 成功色 - 薄荷绿：清新、完成、积极
  /// 用于：完成状态、成功提示
  static const Color success = Color(0xFF4ECDC4);
  static const Color successLight = Color(0xFF7EDDD6);
  static const Color successDark = Color(0xFF3DBDB4);

  /// 警告色 - 琥珀黄：注意、提醒
  static const Color warning = Color(0xFFFFB347);
  static const Color warningLight = Color(0xFFFFCC80);
  static const Color warningDark = Color(0xFFE59A2E);

  /// 危险色 - 玫瑰红：错误、删除
  static const Color danger = Color(0xFFE74C3C);
  static const Color dangerLight = Color(0xFFEF6F61);
  static const Color dangerDark = Color(0xFFC0392B);

  // ══════════════════════════════════════════════════════════════════════════
  // 中性色板 - Neutral Palette
  // ══════════════════════════════════════════════════════════════════════════

  /// 文字色
  static const Color ink = Color(0xFF1A1A2E);        // 主文字 - 深蓝灰
  static const Color inkLight = Color(0xFF4A4A5A);   // 次要文字
  static const Color inkMuted = Color(0xFF8A8A9A);   // 弱化文字
  static const Color inkHint = Color(0xFFB0B0C0);    // 提示文字

  /// 背景色 - 暖色调
  static const Color canvas = Color(0xFFFAFAF8);     // 画布背景 - 暖白
  static const Color surface = Color(0xFFFFFFFF);    // 卡片表面 - 纯白
  static const Color surfaceAlt = Color(0xFFF5F5F3); // 次级表面 - 暖灰
  static const Color surfaceMuted = Color(0xFFEFEFED); // 弱化表面

  /// 边框色
  static const Color border = Color(0xFFE8E8E6);     // 默认边框
  static const Color borderLight = Color(0xFFF0F0EE); // 浅边框
  static const Color borderDark = Color(0xFFD0D0CE); // 深边框

  // ══════════════════════════════════════════════════════════════════════════
  // 语义色板 - Semantic Palette
  // ══════════════════════════════════════════════════════════════════════════

  /// 四象限色彩 - 任务优先级
  static const Color urgentImportant = Color(0xFFFF6B6B);     // 紧急重要 - 珊瑚橙
  static const Color importantNotUrgent = Color(0xFF0D7377);  // 重要不紧急 - 主色
  static const Color urgentNotImportant = Color(0xFFFFB347);  // 紧急不重要 - 琥珀黄
  static const Color notUrgentNotImportant = Color(0xFF8A8A9A); // 不紧急不重要 - 灰色

  /// 软背景色 - 用于标签、徽章背景
  static const Color softPrimary = Color(0xFFE8F4F4);   // 主色软背景
  static const Color softAccent = Color(0xFFFFEBEB);    // 强调色软背景
  static const Color softSuccess = Color(0xFFE8F7F5);   // 成功色软背景
  static const Color softWarning = Color(0xFFFFF4E8);   // 警告色软背景
  static const Color softDanger = Color(0xFFFFE8E8);    // 危险色软背景

  // ══════════════════════════════════════════════════════════════════════════
  // 暗色模式 - Dark Mode
  // ══════════════════════════════════════════════════════════════════════════

  static const Color darkCanvas = Color(0xFF0D0D12);      // 暗色画布
  static const Color darkSurface = Color(0xFF1A1A22);     // 暗色卡片
  static const Color darkSurfaceAlt = Color(0xFF24242E);  // 暗色次级表面
  static const Color darkSurfaceMuted = Color(0xFF2E2E38); // 暗色弱化表面
  static const Color darkBorder = Color(0xFF3A3A44);      // 暗色边框
  static const Color darkInk = Color(0xFFF0F0F5);         // 暗色文字
  static const Color darkInkMuted = Color(0xFFA0A0B0);    // 暗色弱化文字

  static const Color darkSoftPrimary = Color(0xFF1A2E2E);
  static const Color darkSoftAccent = Color(0xFF2E1A1A);
  static const Color darkSoftSuccess = Color(0xFF1A2E28);
  static const Color darkSoftWarning = Color(0xFF2E241A);
  static const Color darkSoftDanger = Color(0xFF2E1A1A);

  // ══════════════════════════════════════════════════════════════════════════
  // 渐变色 - Gradients
  // ══════════════════════════════════════════════════════════════════════════

  /// Hero卡片渐变 - 深青到薄荷
  static const List<Color> heroGradient = [
    Color(0xFF0D7377),
    Color(0xFF14A3A8),
    Color(0xFF4ECDC4),
  ];

  /// 页面背景渐变 - 暖色调
  static const List<Color> pageGradient = [
    Color(0xFFFAFAF8),
    Color(0xFFF5F5F3),
    Color(0xFFF0F0EE),
  ];

  /// 暗色页面背景渐变
  static const List<Color> darkPageGradient = [
    Color(0xFF0D0D12),
    Color(0xFF121218),
    Color(0xFF1A1A22),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 设计令牌 - Design Tokens
  // ══════════════════════════════════════════════════════════════════════════

  /// 圆角
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 999;

  /// 间距
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;

  /// 动效时长
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  /// 阴影
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: ink.withValues(alpha: 0.06),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: ink.withValues(alpha: 0.08),
      offset: const Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  // 向后兼容别名
  // ══════════════════════════════════════════════════════════════════════════

  static const Color textMuted = inkMuted;
  static const Color paper = canvas;
  static const Color blush = primary;
  static const Color softBlue = softPrimary;
  static const Color softGreen = softSuccess;
  static const Color softAmber = softWarning;
  static const Color softRose = softAccent;
  static const Color softViolet = softPrimary;
  static const Color pageBgTop = canvas;
  static const Color pageBgMid = surfaceAlt;
  static const Color pageBgBottom = surfaceMuted;
  static const Color panel = surface;
  static const Color panelBorder = border;
  static const Color heroStart = Color(0xFF0D7377);
  static const Color heroMid = Color(0xFF14A3A8);
  static const Color heroEnd = Color(0xFF4ECDC4);
  static const Color errorBg = softDanger;
  static const Color errorBorder = dangerLight;
  static const Color warnBg = softWarning;
  static const Color warnBorder = warningLight;
  static const Color neutral = inkMuted;
  static const Color neutralStrong = inkLight;
  static const Color info = primary;

  // 动效兼容
  static const Duration motionFast = durationFast;
  static const Duration motionMedium = durationNormal;
  static const Duration motionSlow = durationSlow;

  // ══════════════════════════════════════════════════════════════════════════
  // 主题构建
  // ══════════════════════════════════════════════════════════════════════════

  static WidgetStateProperty<Color?> _overlay(Color color, [double alpha = 0.08]) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return color.withValues(alpha: alpha);
      if (states.contains(WidgetState.hovered)) return color.withValues(alpha: alpha * 0.7);
      if (states.contains(WidgetState.focused)) return color.withValues(alpha: alpha * 0.5);
      return null;
    });
  }

  /// 亮色主题
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: accent,
      surface: canvas,
      surfaceContainerHighest: surfaceAlt,
      error: danger,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: canvas,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: const TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primary),
          foregroundColor: const WidgetStatePropertyAll(primary),
          animationDuration: durationFast,
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primary, 0.1),
          foregroundColor: const WidgetStatePropertyAll(primary),
          animationDuration: durationFast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primary),
          animationDuration: durationFast,
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd))),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusMd))),
      ),
      switchTheme: SwitchThemeData(
        overlayColor: _overlay(primary),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.45);
          return border;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
    );
  }

  /// 暗色主题
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: accentLight,
      surface: darkSurface,
      surfaceContainerHighest: darkSurfaceAlt,
      error: dangerLight,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: darkCanvas,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: darkInk,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: const TextStyle(fontSize: 12, color: darkInk, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primaryLight),
          foregroundColor: const WidgetStatePropertyAll(primaryLight),
          animationDuration: durationFast,
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primaryLight, 0.1),
          foregroundColor: const WidgetStatePropertyAll(primaryLight),
          animationDuration: durationFast,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          overlayColor: _overlay(primaryLight),
          animationDuration: durationFast,
          side: const WidgetStatePropertyAll(BorderSide(color: darkBorder)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd))),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radiusMd))),
      ),
      switchTheme: SwitchThemeData(
        overlayColor: _overlay(primaryLight),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight.withValues(alpha: 0.45);
          return darkBorder;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryLight;
          return Colors.white;
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dangerLight),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: dangerLight, width: 1.5),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 0.5),
    );
  }
}
