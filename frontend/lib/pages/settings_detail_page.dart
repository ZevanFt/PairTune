import 'package:flutter/material.dart';

import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class SettingsDetailPage extends StatelessWidget {
  const SettingsDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: AppSurface.subtleCard(),
              child: Text(subtitle, style: AppText.bodyMuted()),
            ),
            AppSpace.h12,
            ...items.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: AppSpace.xs),
                decoration: AppSurface.card(alpha: 0.93, shadow: false),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.chevron_right_rounded, size: 18),
                  title: Text(item, style: AppText.cardTitle.copyWith(fontSize: 15)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

