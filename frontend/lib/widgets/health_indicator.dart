import 'package:flutter/material.dart';

import '../models/backend_health.dart';
import '../ui/app_theme.dart';

/// Health status dot indicator - replaces duplicated _buildHealthDot across pages.
class HealthDot extends StatelessWidget {
  const HealthDot({super.key, required this.status});

  final BackendHealthStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.online ? AppTheme.success : AppTheme.danger;
    return Tooltip(
      message: status.online ? '服务正常' : '服务异常: ${status.statusText}',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Title row with inline health dot.
class TitleWithHealth extends StatelessWidget {
  const TitleWithHealth({
    super.key,
    required this.title,
    required this.status,
  });

  final String title;
  final BackendHealthStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        HealthDot(status: status),
      ],
    );
  }
}
