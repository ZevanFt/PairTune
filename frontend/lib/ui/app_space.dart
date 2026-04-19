import 'package:flutter/material.dart';

import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Priority First 间距系统 v2.0
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 间距原则：
/// 1. 4px 基础单位 - 所有间距都是 4 的倍数
/// 2. 语义化命名 - 间距名称反映其用途
/// 3. 一致性 - 相同场景使用相同间距
/// ─────────────────────────────────────────────────────────────────────────────

class AppSpace {
  // ══════════════════════════════════════════════════════════════════════════
  // 基础间距
  // ══════════════════════════════════════════════════════════════════════════

  static const double xxs = 4;   // 极小间距 - 紧凑元素内部
  static const double xs = 8;    // 小间距 - 相关元素之间
  static const double sm = 12;   // 标准小间距 - 列表项内部
  static const double md = 16;   // 标准间距 - 卡片内边距
  static const double lg = 20;   // 大间距 - 区块之间
  static const double xl = 24;   // 区块间距 - 主要区块
  static const double xxl = 32;  // 大区块间距 - 页面区块
  static const double xxxl = 48; // 超大间距 - 页面顶部/底部

  // ══════════════════════════════════════════════════════════════════════════
  // 语义间距
  // ══════════════════════════════════════════════════════════════════════════

  static const double inline = xxs;      // 行内间距
  static const double compact = xs;      // 紧凑布局
  static const double comfortable = sm;  // 舒适布局
  static const double relaxed = md;      // 宽松布局
  static const double spacious = lg;     // 宽敞布局

  // ══════════════════════════════════════════════════════════════════════════
  // 预设间距 Widget
  // ══════════════════════════════════════════════════════════════════════════

  /// 水平间距
  static const SizedBox w4 = SizedBox(width: xxs);
  static const SizedBox w8 = SizedBox(width: xs);
  static const SizedBox w10 = SizedBox(width: 10);
  static const SizedBox w12 = SizedBox(width: sm);
  static const SizedBox w16 = SizedBox(width: md);
  static const SizedBox w20 = SizedBox(width: lg);
  static const SizedBox w24 = SizedBox(width: xl);

  /// 垂直间距
  static const SizedBox h4 = SizedBox(height: xxs);
  static const SizedBox h8 = SizedBox(height: xs);
  static const SizedBox h10 = SizedBox(height: 10);
  static const SizedBox h12 = SizedBox(height: sm);
  static const SizedBox h16 = SizedBox(height: md);
  static const SizedBox h20 = SizedBox(height: lg);
  static const SizedBox h24 = SizedBox(height: xl);
  static const SizedBox h32 = SizedBox(height: xxl);

  // ══════════════════════════════════════════════════════════════════════════
  // 边距预设
  // ══════════════════════════════════════════════════════════════════════════

  /// 卡片内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  /// 列表项内边距
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  /// 页面内边距
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// 表单内边距
  static const EdgeInsets formPadding = EdgeInsets.fromLTRB(lg, lg, lg, xxxl);

  /// 按钮内边距
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}
