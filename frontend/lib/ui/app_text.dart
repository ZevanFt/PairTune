import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppText {
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppTheme.ink,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 12,
    color: AppTheme.textMuted,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppTheme.ink,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 12,
    color: AppTheme.textMuted,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle chipText = TextStyle(
    fontSize: 10.5,
    color: AppTheme.ink,
    fontWeight: FontWeight.w600,
  );
}

