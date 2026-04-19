import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Priority First 表面装饰系统 v2.0
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 表面原则：
/// 1. 层次分明 - 不同表面有清晰的视觉层次
/// 2. 微妙深度 - 使用阴影而非边框创造深度
/// 3. 一致性 - 相同场景使用相同表面样式
/// ─────────────────────────────────────────────────────────────────────────────

class AppSurface {
  // ══════════════════════════════════════════════════════════════════════════
  // 卡片装饰
  // ══════════════════════════════════════════════════════════════════════════

  /// 主卡片 - 带阴影的主要卡片
  static BoxDecoration card({
    Color? color,
    bool shadow = true,
    double? radius,
    double? alpha,
  }) {
    final baseColor = color ?? AppTheme.surface;
    return BoxDecoration(
      color: alpha != null ? baseColor.withValues(alpha: alpha) : baseColor,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusLg),
      boxShadow: shadow ? AppTheme.shadowMd : null,
    );
  }

  /// 次级卡片 - 无阴影的次要卡片
  static BoxDecoration subtleCard({Color? color, double? radius}) {
    return BoxDecoration(
      color: color ?? AppTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusMd),
    );
  }

  /// 交互卡片 - 可点击的卡片
  static BoxDecoration interactiveCard({
    Color? color,
    bool pressed = false,
    double? radius,
  }) {
    return BoxDecoration(
      color: color ?? AppTheme.surface,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusLg),
      border: Border.all(
        color: pressed ? AppTheme.primary : AppTheme.border,
        width: pressed ? 1.5 : 1,
      ),
      boxShadow: pressed ? null : AppTheme.shadowSm,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 语义表面
  // ══════════════════════════════════════════════════════════════════════════

  /// 成功面板
  static BoxDecoration successPanel() {
    return BoxDecoration(
      color: AppTheme.softSuccess,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
    );
  }

  /// 警告面板
  static BoxDecoration warningPanel() {
    return BoxDecoration(
      color: AppTheme.softWarning,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
    );
  }

  /// 错误面板
  static BoxDecoration errorPanel() {
    return BoxDecoration(
      color: AppTheme.softDanger,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
    );
  }

  /// 信息面板
  static BoxDecoration infoPanel() {
    return BoxDecoration(
      color: AppTheme.softPrimary,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Hero 卡片
  // ══════════════════════════════════════════════════════════════════════════

  /// Hero 卡片 - 渐变背景的大卡片
  static BoxDecoration heroCard({
    List<Color>? gradient,
    double? radius,
  }) {
    final colors = gradient ?? [AppTheme.heroGradient, AppTheme.primary];
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusXl),
      boxShadow: AppTheme.shadowLg,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 标签/徽章
  // ══════════════════════════════════════════════════════════════════════════

  /// 标签背景
  static BoxDecoration badge({
    required Color color,
    double? radius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusSm),
    );
  }

  /// 软标签背景
  static BoxDecoration softBadge({
    required Color backgroundColor,
    Color? borderColor,
    double? radius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius ?? AppTheme.radiusSm),
      border: borderColor != null ? Border.all(color: borderColor) : null,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // 预设常量
  // ══════════════════════════════════════════════════════════════════════════

  /// 卡片圆角
  static final BorderRadius cardRadius = BorderRadius.circular(AppTheme.radiusLg);

  /// 小圆角
  static final BorderRadius smallRadius = BorderRadius.circular(AppTheme.radiusSm);

  /// 软阴影
  static final List<BoxShadow> softShadow = AppTheme.shadowSm;

  /// 中等阴影
  static final List<BoxShadow> mediumShadow = AppTheme.shadowMd;

  // ══════════════════════════════════════════════════════════════════════════
  // 向后兼容
  // ══════════════════════════════════════════════════════════════════════════

  static BoxDecoration warnPanel() => warningPanel();
}
