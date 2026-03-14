import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({
    super.key,
    required this.onLogin,
    required this.onGuest,
  });

  final VoidCallback onLogin;
  final VoidCallback onGuest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    AppStrings.appTag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                AppSpace.h12,
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                AppSpace.h8,
                const Text(AppStrings.appSubtitle, style: AppText.sectionSubtitle),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        _AuthFeatureRow(
                          title: AppStrings.introFeatureTitle1,
                          subtitle: AppStrings.introFeatureSubtitle1,
                          icon: Icons.grid_view_rounded,
                        ),
                        AppSpace.h12,
                        _AuthFeatureRow(
                          title: AppStrings.introFeatureTitle2,
                          subtitle: AppStrings.introFeatureSubtitle2,
                          icon: Icons.stars_rounded,
                        ),
                        AppSpace.h12,
                        _AuthFeatureRow(
                          title: AppStrings.introFeatureTitle3,
                          subtitle: AppStrings.introFeatureSubtitle3,
                          icon: Icons.people_alt_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onLogin,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text(AppStrings.introLogin),
                  ),
                ),
                AppSpace.h8,
                Center(
                  child: TextButton(
                    onPressed: onGuest,
                    child: const Text(AppStrings.introGuest),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFeatureRow extends StatelessWidget {
  const _AuthFeatureRow({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: AppSurface.card(alpha: 0.9, shadow: false),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.bodyMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
