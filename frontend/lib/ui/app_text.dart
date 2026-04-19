import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Linear Design Typography System
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 排版原则：
/// 1. 简洁清晰 - 字重适中，不过度强调
/// 2. 层次分明 - 通过字号和颜色区分层次
/// 3. 易读舒适 - 合理的行高和字间距
/// ─────────────────────────────────────────────────────────────────────────────

class AppText {
  // ══════════════════════════════════════════════════════════════════════════
  // Display - 大标题
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle display1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppTheme.ink,
  );

  static const TextStyle display2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Heading - 标题
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle heading1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppTheme.ink,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppTheme.ink,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Body - 正文
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppTheme.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: AppTheme.ink,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Caption - 说明文字
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppTheme.inkSecondary,
  );

  static const TextStyle captionSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.35,
    color: AppTheme.inkTertiary,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 特殊样式
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppTheme.inkTertiary,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppTheme.ink,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.ink,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.3,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 动态样式
  // ══════════════════════════════════════════════════════════════════════════

  static TextStyle bodyMuted({Color? color}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: color ?? AppTheme.inkTertiary,
        height: 1.5,
      );

  static TextStyle sectionTitleStyle({Color? color}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppTheme.inkTertiary,
        height: 1.3,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // 向后兼容
  // ══════════════════════════════════════════════════════════════════════════

  static const TextStyle largeTitle = display2;
  static const TextStyle title1 = heading1;
  static const TextStyle title2 = heading2;
  static const TextStyle title3 = heading3;
  static const TextStyle headline = heading3;
  static const TextStyle callout = body;
  static const TextStyle subhead = bodySm;
  static const TextStyle footnote = caption;
  static const TextStyle chipText = label;
}
