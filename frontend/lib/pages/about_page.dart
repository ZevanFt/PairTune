import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../ui/app_surface.dart';
import '../ui/app_space.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.aboutTitle)),
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
            _buildHeader(),
            AppSpace.h16,
            _buildSection(
              title: AppStrings.aboutSectionAuthor,
              items: const [
                _InfoRow(label: AppStrings.aboutAuthorLabel, value: AppStrings.appTeamName),
                _InfoRow(label: AppStrings.aboutVersionLabel, value: AppStrings.appVersion),
              ],
            ),
            AppSpace.h12,
            _buildSection(
              title: AppStrings.aboutSectionOpenSource,
              description: AppStrings.aboutOpenSourceDesc,
              items: const [
                _InfoRow(label: AppStrings.aboutFrameworkLabel, value: AppStrings.aboutFrameworkValue),
                _InfoRow(label: AppStrings.aboutUiLabel, value: AppStrings.aboutUiValue),
                _InfoRow(label: AppStrings.aboutDataLabel, value: AppStrings.aboutDataValue),
                _InfoRow(label: AppStrings.aboutNetLabel, value: AppStrings.aboutNetValue),
                _InfoRow(label: AppStrings.aboutLicenseLabel, value: AppStrings.aboutLicenseValue),
              ],
            ),
            AppSpace.h12,
            _buildSection(
              title: AppStrings.aboutSectionDeps,
              items: const [
                _InfoRow(label: AppStrings.aboutDepFlutter, value: AppStrings.aboutDepSdk),
                _InfoRow(label: AppStrings.aboutDepCupertino, value: AppStrings.aboutDepCupertinoVersion),
                _InfoRow(label: AppStrings.aboutDepSqflite, value: AppStrings.aboutDepSqfliteVersion),
                _InfoRow(label: AppStrings.aboutDepPath, value: AppStrings.aboutDepPathVersion),
                _InfoRow(label: AppStrings.aboutDepIntl, value: AppStrings.aboutDepIntlVersion),
                _InfoRow(label: AppStrings.aboutDepHttp, value: AppStrings.aboutDepHttpVersion),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppSurface.card(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.aboutHeaderTitle,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          AppSpace.h8,
          const Text(AppStrings.aboutHeaderSubtitle, style: AppText.sectionSubtitle),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? description,
    required List<_InfoRow> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppSurface.card(alpha: 0.96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.sectionTitle),
          if (description != null) ...[
            AppSpace.h8,
            Text(description, style: AppText.bodyMuted),
          ],
          AppSpace.h10,
          ...items,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppText.bodyMuted.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: AppText.sectionSubtitle.copyWith(color: AppTheme.ink))),
        ],
      ),
    );
  }
}
