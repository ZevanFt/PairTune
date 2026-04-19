import 'package:flutter/material.dart';
import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Linear Design Typography System
/// ─────────────────────────────────────────────────────────────────────────────

class AppText {
  AppText._();

  // Display
  static const TextStyle display1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppTheme.ink,
  );

  static const TextStyle display2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppTheme.ink,
  );

  // Heading
  static const TextStyle heading1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppTheme.ink,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppTheme.ink,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
    color: AppTheme.ink,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppTheme.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppTheme.ink,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppTheme.ink,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppTheme.inkSecondary,
  );

  static const TextStyle captionSm = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppTheme.inkTertiary,
  );

  static const TextStyle micro = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  // Special
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
    color: AppTheme.inkTertiary,
  );

  static const TextStyle sectionSubtitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.inkMuted,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppTheme.ink,
  );

  // Dynamic
  static TextStyle bodyMuted({Color? color}) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color ?? AppTheme.inkTertiary,
    height: 1.5,
  );

  // Backward compatibility
  static const TextStyle largeTitle = display2;
  static const TextStyle title1 = heading1;
  static const TextStyle title2 = heading2;
  static const TextStyle title3 = heading3;
  static const TextStyle headline = heading3;
  static const TextStyle callout = body;
  static const TextStyle subhead = bodySm;
  static const TextStyle footnote = caption;
  static const TextStyle chipText = label;
  static const TextStyle cardTitle = heading3;
}
