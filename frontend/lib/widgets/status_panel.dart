import 'package:flutter/material.dart';

import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

/// Error panel widget - replaces duplicated _buildErrorPanel across pages.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppSurface.errorPanel(),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppText.subhead.copyWith(color: AppTheme.danger))),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}

/// Warning panel widget - replaces duplicated _buildWarnBanner across pages.
class WarnPanel extends StatelessWidget {
  const WarnPanel({
    super.key,
    required this.message,
    this.onAction,
    this.actionLabel = '了解',
  });

  final String message;
  final VoidCallback? onAction;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppSurface.warnPanel(),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppText.subhead.copyWith(color: AppTheme.warning))),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

/// Guest mode banner - shown when user is in guest/dev mode.
class GuestBanner extends StatelessWidget {
  const GuestBanner({
    super.key,
    required this.onExit,
  });

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: AppSurface.warnPanel(),
      child: Row(
        children: [
          Icon(Icons.person_outline_rounded, color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('体验模式：部分功能已隐藏', style: AppText.subhead),
          ),
          TextButton(
            onPressed: onExit,
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }
}
