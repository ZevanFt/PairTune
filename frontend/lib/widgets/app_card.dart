import 'package:flutter/material.dart';

import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_theme.dart';

/// 卡片类型
enum AppCardType {
  /// 主卡片 - 带阴影
  primary,
  /// 次级卡片 - 无阴影
  subtle,
  /// 错误卡片
  error,
  /// 警告卡片
  warning,
}

/// 统一的卡片组件
/// 替代所有页面内的 _card() 方法
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.type = AppCardType.primary,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
  });

  final Widget child;
  final AppCardType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? borderColor;

  BoxDecoration _getDecoration() {
    switch (type) {
      case AppCardType.primary:
        return AppSurface.card(color: color);
      case AppCardType.subtle:
        return AppSurface.subtleCard(color: color);
      case AppCardType.error:
        return AppSurface.errorPanel();
      case AppCardType.warning:
        return AppSurface.warnPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpace.md),
      decoration: _getDecoration(),
      child: child,
    );

    final withBorder = showBorder
        ? Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: borderColor ?? AppTheme.border,
                width: 1,
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: card,
          )
        : card;

    final withMargin = margin != null
        ? Padding(padding: margin!, child: withBorder)
        : withBorder;

    if (onTap != null || onLongPress != null) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radiusLg),
        child: withMargin,
      );
    }

    return withMargin;
  }
}

/// 带标题的卡片
class AppTitledCard extends StatelessWidget {
  const AppTitledCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.type = AppCardType.primary,
    this.padding,
    this.margin,
    this.titlePadding,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final AppCardType type;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? titlePadding;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: type,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: titlePadding ?? EdgeInsets.zero,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textMuted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          child,
        ],
      ),
    );
  }
}

/// 列表项卡片
class AppListCard extends StatelessWidget {
  const AppListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.type = AppCardType.subtle,
    this.margin,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final AppCardType type;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      type: type,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      margin: margin ?? const EdgeInsets.only(bottom: AppSpace.xs),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
