import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/profile_config.dart';
import '../i18n/app_strings.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key});

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final _passwordController = TextEditingController();
  bool _loginAlert = true;
  bool _riskGuard = true;
  int _strength = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loginAlert = prefs.getBool(ProfileConfig.prefSecurityLoginAlert) ?? true;
      _riskGuard = prefs.getBool(ProfileConfig.prefSecurityRiskGuard) ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ProfileConfig.prefSecurityLoginAlert, _loginAlert);
    await prefs.setBool(ProfileConfig.prefSecurityRiskGuard, _riskGuard);
  }

  void _updateStrength(String value) {
    final text = value.trim();
    int score = 0;
    if (text.length >= 8) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(text) && RegExp(r'[a-z]').hasMatch(text)) {
      score += 1;
    }
    if (RegExp(r'\d').hasMatch(text)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text)) score += 1;

    setState(() => _strength = score.clamp(0, 3));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountSecurityTitle)),
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
              AppStrings.accountSecuritySectionAlerts,
              '',
            ),
            AppSpace.h8,
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppSurface.card(alpha: 0.95),
              child: Column(
                children: [
                  _buildSwitchItem(
                    AppStrings.accountSecurityLoginAlert,
                    AppStrings.accountSecurityLoginAlertHint,
                    _loginAlert,
                    (value) {
                      setState(() => _loginAlert = value);
                      _savePrefs();
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchItem(
                    AppStrings.accountSecurityRiskGuard,
                    AppStrings.accountSecurityRiskGuardHint,
                    _riskGuard,
                    (value) {
                      setState(() => _riskGuard = value);
                      _savePrefs();
                    },
                  ),
                ],
              ),
            ),
            AppSpace.h16,
            _buildSectionTitle(
              AppStrings.accountSecuritySectionCheck,
              AppStrings.accountSecurityPasswordHint,
            ),
            AppSpace.h8,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppSurface.card(alpha: 0.95),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.accountSecurityPassword,
                    ),
                    onChanged: _updateStrength,
                  ),
                  const SizedBox(height: 12),
                  _buildStrengthBar(),
                  const SizedBox(height: 8),
                  Text(
                    '${AppStrings.accountSecurityStrengthLabel}：${_strengthLabel()}',
                    style: AppText.bodyMuted,
                  ),
                  const SizedBox(height: 10),
                  _buildStrengthTips(),
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

  Widget _buildSwitchItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text(subtitle, style: AppText.bodyMuted),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildStrengthBar() {
    final colors = [
      AppTheme.border,
      AppTheme.warning,
      AppTheme.success,
    ];

    return Row(
      children: List.generate(3, (index) {
        final active = _strength >= index + 1;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? colors[index] : AppTheme.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStrengthTips() {
    final tips = [
      AppStrings.accountSecurityTipShort,
      AppStrings.accountSecurityTipMix,
      AppStrings.accountSecurityTipSymbol,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tips
          .map(
            (tip) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: AppSurface.subtleCard(shadow: false),
              child: Text(tip, style: AppText.bodyMuted),
            ),
          )
          .toList(),
    );
  }

  String _strengthLabel() {
    if (_strength <= 1) return AppStrings.accountSecurityWeak;
    if (_strength == 2) return AppStrings.accountSecurityMedium;
    return AppStrings.accountSecurityStrong;
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppTheme.border);
  }
}
