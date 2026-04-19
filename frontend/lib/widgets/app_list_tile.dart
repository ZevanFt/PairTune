import 'package:flutter/material.dart';

import '../ui/app_space.dart';
import '../ui/app_theme.dart';

/// 统一的列表项组件
/// 替代所有页面内的自定义列表项
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.contentPadding,
    this.isThreeLine = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      leading: leading,
      trailing: trailing,
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      enabled: enabled,
      selected: selected,
      dense: dense,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: AppSpace.sm),
      isThreeLine: isThreeLine,
    );
  }
}

/// 带图标的列表项
class AppIconListTile extends StatelessWidget {
  const AppIconListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.iconColor,
    this.iconSize = 20,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? iconColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppTheme.primary,
        size: iconSize,
      ),
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// 带开关的列表项
class AppSwitchListTile extends StatelessWidget {
  const AppSwitchListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
    );
  }
}

/// 带复选框的列表项
class AppCheckboxListTile extends StatelessWidget {
  const AppCheckboxListTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
    );
  }
}

/// 带箭头的列表项 (用于导航)
class AppNavigationListTile extends StatelessWidget {
  const AppNavigationListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.arrowIcon = Icons.chevron_right_rounded,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final IconData arrowIcon;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Icon(arrowIcon, color: AppTheme.textMuted, size: 20),
      onTap: onTap,
    );
  }
}

/// 分组列表头
class AppListSectionHeader extends StatelessWidget {
  const AppListSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.lg, AppSpace.sm, AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
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
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 列表分隔线
class AppListDivider extends StatelessWidget {
  const AppListDivider({
    super.key,
    this.indent,
    this.endIndent,
    this.thickness = 1,
  });

  final double? indent;
  final double? endIndent;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: thickness,
      color: AppTheme.border,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
