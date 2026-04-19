import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Priority First 排版系统 v2.0
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 排版原则：
/// 1. 层次分明 - 标题、正文、说明文字有清晰的视觉层次
/// 2. 易读舒适 - 字号、行高、字间距经过精心调整
/// 3. 一致性强 - 统一的排版规范，减少认知负担
///
/// 字体层级：
/// - Display: 32-40pt - 大标题、Hero区域
/// - Heading: 20-28pt - 区块标题、卡片标题
/// - Body: 14-17pt - 正文、列表项
/// - Caption: 11-13pt - 说明、时间戳、标签
/// ─────────────────────────────────────────────────────────────────────────────

class AppText {
  // ══════════════════════════════════════════════════════════════════════════
  // Display 层级 - 大标题
  // ══════════════════════════════════════════════════════════════════════════

  /// 超大标题 - 40pt，用于引导页、空状态
  static const TextStyle display1 = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.15,
    color: AppTheme.ink,
  );

  /// 大标题 - 32pt，用于页面主标题
  static const TextStyle display2 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Heading 层级 - 标题
  // ══════════════════════════════════════════════════════════════════════════

  /// 标题1 - 24pt，用于区块大标题
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppTheme.ink,
  );

  /// 标题2 - 20pt，用于卡片标题、列表分组标题
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppTheme.ink,
  );

  /// 标题3 - 18pt，用于列表项标题
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Body 层级 - 正文
  // ══════════════════════════════════════════════════════════════════════════

  /// 正文大 - 17pt，用于重要正文
  static const TextStyle bodyLg = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.5,
    color: AppTheme.ink,
  );

  /// 正文 - 15pt，用于常规正文、列表项
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
    height: 1.5,
    color: AppTheme.ink,
  );

  /// 正文小 - 14pt，用于紧凑布局
  static const TextStyle bodySm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
    color: AppTheme.ink,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Caption 层级 - 说明文字
  // ══════════════════════════════════════════════════════════════════════════

  /// 说明 - 13pt，用于副标题、说明文字
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.4,
    color: AppTheme.inkMuted,
  );

  /// 说明小 - 12pt，用于时间戳、标签
  static const TextStyle captionSm = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.35,
    color: AppTheme.inkMuted,
  );

  /// 微型 - 11pt，用于极小提示
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 特殊样式
  // ══════════════════════════════════════════════════════════════════════════

  /// 区块标题 - 带强调条的小标题
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  /// 区块副标题
  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.inkHint,
  );

  /// 卡片标题
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.35,
    color: AppTheme.ink,
  );

  /// 标签文字
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.3,
    color: AppTheme.ink,
  );

  /// 按钮文字
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 动态样式 - 支持颜色自定义
  // ══════════════════════════════════════════════════════════════════════════

  /// 弱化正文
  static TextStyle bodyMuted({Color? color}) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: color ?? AppTheme.inkMuted,
        height: 1.5,
      );

  /// 区块标题样式
  static TextStyle sectionTitleStyle({Color? color}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: color ?? AppTheme.inkMuted,
        height: 1.3,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // 向后兼容别名
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
