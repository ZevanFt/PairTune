import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppSurface {
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius subtleRadius = BorderRadius.all(Radius.circular(14));

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0F1F2E48),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x0D1F2E48),
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static BoxDecoration card({
    double alpha = 0.94,
    bool shadow = true,
  }) {
    return BoxDecoration(
      color: AppTheme.panel.withValues(alpha: alpha),
      borderRadius: cardRadius,
      border: Border.all(color: AppTheme.panelBorder),
      boxShadow: shadow ? softShadow : null,
    );
  }

  static BoxDecoration subtleCard({
    double alpha = 0.9,
    bool shadow = false,
  }) {
    return BoxDecoration(
      color: AppTheme.panel.withValues(alpha: alpha),
      borderRadius: subtleRadius,
      border: Border.all(color: AppTheme.panelBorder),
      boxShadow: shadow ? subtleShadow : null,
    );
  }
}

