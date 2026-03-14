import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/profile_config.dart';
import '../data/task_db.dart';
import '../i18n/app_strings.dart';
import '../services/store_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';

class PrivacyDataPage extends StatefulWidget {
  const PrivacyDataPage({super.key});

  @override
  State<PrivacyDataPage> createState() => _PrivacyDataPageState();
}

class _PrivacyDataPageState extends State<PrivacyDataPage> {
  final _storeApi = StoreApiService();
  final _taskDb = TaskDb.instance;

  int _tasks = 0;
  int _products = 0;
  int _ledger = 0;
  bool _loading = false;
  String? _error;

  Future<void> _loadSnapshot() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _storeApi.exportSnapshot();
      final tasks = (snapshot['tasks'] as List<dynamic>? ?? const []).length;
      final products =
          (snapshot['products'] as List<dynamic>? ?? const []).length;
      final ledger = (snapshot['ledger'] as List<dynamic>? ?? const []).length;
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _products = products;
        _ledger = ledger;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.privacySnapshotReady)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmAndClearTasks() async {
    final confirmed = await _confirmAction(AppStrings.privacyClearTasks);
    if (confirmed != true) return;
    await _taskDb.clearAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.privacyClearedTasks)),
    );
  }

  Future<void> _confirmAndClearPrefs() async {
    final confirmed = await _confirmAction(AppStrings.privacyClearPrefs);
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ProfileConfig.prefRelationshipCheckin);
    await prefs.remove(ProfileConfig.prefRelationshipReminder);
    await prefs.remove(ProfileConfig.prefRelationshipCoopHint);
    await prefs.remove(ProfileConfig.prefSecurityLoginAlert);
    await prefs.remove(ProfileConfig.prefSecurityRiskGuard);
    await prefs.remove(ProfileConfig.prefFeedbackItems);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.privacyClearedPrefs)),
    );
  }

  Future<bool?> _confirmAction(String title) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppStrings.privacyConfirmTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.privacyConfirmDetailText(title),
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(AppStrings.privacyConfirmCancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(AppStrings.privacyConfirmOk),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.privacyTitle)),
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
            _buildSectionTitle(
              AppStrings.privacySectionSnapshot,
              AppStrings.privacySectionSnapshotHint,
            ),
            AppSpace.h8,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppSurface.card(alpha: 0.95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.privacySnapshotSummary(_tasks, _products, _ledger),
                    style: AppText.cardTitle,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!, style: AppText.bodyMuted),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _loadSnapshot,
                      child: Text(
                        _loading
                            ? AppStrings.privacySnapshotLoading
                            : AppStrings.privacySnapshotAction,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpace.h16,
            _buildSectionTitle(
              AppStrings.privacySectionLocal,
              '',
            ),
            AppSpace.h8,
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppSurface.card(alpha: 0.95),
              child: Column(
                children: [
                  _buildActionItem(
                    AppStrings.privacyClearTasks,
                    AppStrings.privacyClearTasksHint,
                    _confirmAndClearTasks,
                  ),
                  _buildDivider(),
                  _buildActionItem(
                    AppStrings.privacyClearPrefs,
                    AppStrings.privacyClearPrefsHint,
                    _confirmAndClearPrefs,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (subtitle.isNotEmpty) Text(subtitle, style: AppText.sectionSubtitle),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text(subtitle, style: AppText.bodyMuted),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppTheme.border);
  }
}
