import 'package:flutter/material.dart';
import '../ui/app_theme.dart';
import '../ui/app_text.dart';
import '../ui/app_space.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// PairTune 统一组件库 - Linear风格
/// ─────────────────────────────────────────────────────────────────────────────
///
/// 使用原则：
/// 1. 所有页面必须使用此组件库
/// 2. 禁止内联创建相同UI
/// 3. 通过参数控制变体
/// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
// 页面框架
// ══════════════════════════════════════════════════════════════════════════════

/// 统一页面
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
// 卡片
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

/// 列表卡片
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
// 按钮
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
        side: const BorderSide(color: AppTheme.border),
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
// 标签
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

// ══════════════════════════════════════════════════════════════════════════════
// 分隔
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
// 状态
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
// 输入
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
// 数字显示
// ══════════════════════════════════════════════════════════════════════════════

/// 大数字显示
class AppBigNumber extends StatelessWidget {
  const AppBigNumber({
    super.key,
    required this.value,
    required this.label,
    this.color,
  });

  final int value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: c,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.caption),
      ],
    );
  }
}

/// 徽章数字
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.value,
    this.color,
  });

  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        color: value > 0 ? c.withValues(alpha: 0.1) : AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        '$value',
        style: TextStyle(
          color: value > 0 ? c : AppTheme.inkMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
