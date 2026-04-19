import 'package:flutter/material.dart';
import 'app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Linear Design Spacing System
/// ─────────────────────────────────────────────────────────────────────────────

class AppSpace {
  AppSpace._();

  static const double xs = AppTheme.spaceXs;
  static const double sm = AppTheme.spaceSm;
  static const double md = AppTheme.spaceMd;
  static const double lg = AppTheme.spaceLg;
  static const double xl = AppTheme.spaceXl;
  static const double x2 = AppTheme.space2xl;

  // Backward compatibility
  static const double w4 = xs;
  static const double w8 = sm;
  static const double w10 = 10.0;
  static const double w12 = md;
  static const double w16 = lg;
  static const double w20 = xl;
  static const double w24 = x2;

  // Height shortcuts
  static const SizedBox h4 = SizedBox(height: xs);
  static const SizedBox h8 = SizedBox(height: sm);
  static const SizedBox h10 = SizedBox(height: 10.0);
  static const SizedBox h12 = SizedBox(height: md);
  static const SizedBox h16 = SizedBox(height: lg);
  static const SizedBox h20 = SizedBox(height: xl);
  static const SizedBox h24 = SizedBox(height: x2);

  // Width shortcuts
  static const SizedBox w4w = SizedBox(width: xs);
  static const SizedBox w8w = SizedBox(width: sm);
  static const SizedBox w12w = SizedBox(width: md);
  static const SizedBox w16w = SizedBox(width: lg);
}
