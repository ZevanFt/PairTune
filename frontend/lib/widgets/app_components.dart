import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PairTune 统一组件库
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 使用原则：
/// 1. 所有页面必须使用此组件库，禁止内联创建相同UI
/// 2. 组件自动应用设计系统规范
/// 3. 通过参数控制变体，不创建新组件
/// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
// 页面框架
// ══════════════════════════════════════════════════════════════════════════════

/// 统一页面脚手架
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.children,
    this.appBar,
    this.padding,
    this.onRefresh,
    this.fab,
    this.bottomNav,
  });

  final List<Widget> children;
  final PreferredSizeWidget? appBar;
  final EdgeInsets? padding;
  final Future<void> Function()? onRefresh;
  final Widget? fab;
  final Widget? bottomNav;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      padding: padding ?? const EdgeInsets.all(AppSpace.lg),
      children: children,
    );

    final body = onRefresh != null
        ? RefreshIndicator(onRefresh: onRefresh!, child: list)
        : list;

    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: fab,
      bottomNavigationBar: bottomNav,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 卡片组件
// ══════════════════════════════════════════════════════════════════════════════

/// 统一卡片
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: borderColor ?? AppTheme.border),
      ),
      child: child,
    );

    final withMargin = margin != null ? Padding(padding: margin!, child: card) : card;

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: withMargin,
      );
    }
    return withMargin;
  }
}

/// 统一列表卡片
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpace.sm),
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: AppSpace.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.caption),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: AppSpace.sm), trailing!],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 按钮组件
// ══════════════════════════════════════════════════════════════════════════════

/// 主要按钮
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      ),
      child: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : icon != null
              ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)])
              : Text(label),
    );
  }
}

/// 次要按钮
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.ink,
        side: BorderSide(color: AppTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      ),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)])
          : Text(label),
    );
  }
}

/// 文字按钮
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)])
          : Text(label),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 标签组件
// ══════════════════════════════════════════════════════════════════════════════

/// 统一标签
class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: icon != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color))])
          : Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

/// 四象限标签
class AppQuadrantTag extends StatelessWidget {
  const AppQuadrantTag({super.key, required this.quadrant});

  final TaskQuadrant quadrant;

  Color get _color => switch (quadrant) {
    TaskQuadrant.importantUrgent => AppTheme.urgentImportant,
    TaskQuadrant.importantNotUrgent => AppTheme.importantNotUrgent,
    TaskQuadrant.notImportantUrgent => AppTheme.urgentNotImportant,
    TaskQuadrant.notImportantNotUrgent => AppTheme.notUrgentNotImportant,
  };

  @override
  Widget build(BuildContext context) => AppTag(label: quadrant.label, color: _color);
}

// ══════════════════════════════════════════════════════════════════════════════
// 分隔组件
// ══════════════════════════════════════════════════════════════════════════════

/// 区块标题
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.sectionSubtitle),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// 分隔线
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.margin});

  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Divider(color: AppTheme.border, height: 1),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 状态组件
// ══════════════════════════════════════════════════════════════════════════════

/// 空状态
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.action,
  });

  final String message;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.inbox_outlined, size: 48, color: AppTheme.inkMuted),
          const SizedBox(height: AppSpace.md),
          Text(message, style: AppText.bodyMuted(), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: AppSpace.lg), action!],
        ],
      ),
    );
  }
}

/// 加载状态
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: AppSpace.md), Text(message!, style: AppText.bodyMuted())],
        ],
      ),
    );
  }
}

/// 错误状态
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
          const SizedBox(height: AppSpace.md),
          Text(message, style: AppText.bodyMuted(), textAlign: TextAlign.center),
          if (onRetry != null) ...[const SizedBox(height: AppSpace.lg), AppSecondaryButton(label: '重试', onPressed: onRetry)],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 输入组件
// ══════════════════════════════════════════════════════════════════════════════

/// 统一输入框
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final int maxLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      enabled: enabled,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 辅助类型（需要从其他文件导入）
// ══════════════════════════════════════════════════════════════════════════════

// 这些类型应该从对应的文件导入，这里仅作占位
class TaskQuadrant {
  final String label;
  const TaskQuadrant(this.label);
  static const importantUrgent = TaskQuadrant('紧急重要');
  static const importantNotUrgent = TaskQuadrant('重要不紧急');
  static const notImportantUrgent = TaskQuadrant('紧急不重要');
  static const notImportantNotUrgent = TaskQuadrant('不紧急不重要');
}

class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
}

class AppText {
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.ink);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.inkSecondary);
  static const sectionTitle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.inkTertiary, letterSpacing: 0.5);
  static const sectionSubtitle = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppTheme.inkMuted, letterSpacing: 0.2);
  static TextStyle bodyMuted() => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.inkTertiary);
}
