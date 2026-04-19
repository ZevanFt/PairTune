import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../services/account_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';

class AccountSecurityPage extends StatefulWidget {
  const AccountSecurityPage({super.key, required this.owner});

  final String owner;

  @override
  State<AccountSecurityPage> createState() => _AccountSecurityPageState();
}

class _AccountSecurityPageState extends State<AccountSecurityPage> {
  final _passwordController = TextEditingController();
  final _accountApi = AccountApiService();
  bool _loginAlert = true;
  bool _riskGuard = true;
  int _strength = 0;
  bool _loading = true;
  String? _error;

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
    try {
      final settings = await _accountApi.getSettings(widget.owner);
      if (!mounted) return;
      setState(() {
        _loginAlert = settings.securityLoginAlert;
        _riskGuard = settings.securityRiskGuard;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = formatErrorMessage(e);
      });
    }
  }

  Future<bool> _applySetting({
    bool? loginAlert,
    bool? riskGuard,
  }) async {
    try {
      await _accountApi.updateSettings(
        owner: widget.owner,
        securityLoginAlert: loginAlert,
        securityRiskGuard: riskGuard,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatErrorMessage(e))),
      );
      return false;
    }
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
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: AppText.bodyMuted().copyWith(color: AppTheme.danger),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: AppSurface.card(alpha: 0.95),
              child: Column(
                children: [
                  _buildSwitchItem(
                    AppStrings.accountSecurityLoginAlert,
                    AppStrings.accountSecurityLoginAlertHint,
                    _loginAlert,
                    (value) async {
                      final prev = _loginAlert;
                      setState(() => _loginAlert = value);
                      final ok = await _applySetting(loginAlert: value);
                      if (!mounted) return;
                      if (!ok) {
                        setState(() => _loginAlert = prev);
                      }
                    },
                  ),
                  _buildDivider(),
                  _buildSwitchItem(
                    AppStrings.accountSecurityRiskGuard,
                    AppStrings.accountSecurityRiskGuardHint,
                    _riskGuard,
                    (value) async {
                      final prev = _riskGuard;
                      setState(() => _riskGuard = value);
                      final ok = await _applySetting(riskGuard: value);
                      if (!mounted) return;
                      if (!ok) {
                        setState(() => _riskGuard = prev);
                      }
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
                    style: AppText.bodyMuted(),
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
      subtitle: Text(subtitle, style: AppText.bodyMuted()),
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
              decoration: AppSurface.subtleCard(),
              child: Text(tip, style: AppText.bodyMuted()),
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
