import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../i18n/app_strings.dart';
import '../services/account_api_service.dart';
import '../services/health_api_service.dart';
import '../ui/app_surface.dart';
import '../ui/app_space.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../ui/profile_avatar.dart';
import '../utils/error_display.dart';
import '../widgets/hero_panel.dart';
import 'about_page.dart';
import 'account_security_page.dart';
import 'debug_page.dart';
import 'edit_profile_page.dart';
import 'help_feedback_page.dart';
import 'privacy_data_page.dart';
import 'relationship_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.owner,
    required this.duoEnabled,
    required this.onModeChanged,
    required this.onLogout,
    this.isGuest = false,
    required this.onExitGuest,
  });

  final String owner;
  final bool duoEnabled;
  final ValueChanged<bool> onModeChanged;
  final Future<void> Function() onLogout;
  final bool isGuest;
  final VoidCallback onExitGuest;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _accountApi = AccountApiService();
  final _healthApi = HealthApiService();
  bool _loading = true;
  String? _error;
  BackendHealthStatus? _healthStatus;
  UserProfile? _profile;
  AppSettings? _settings;
  int _debugTapCount = 0;
  int _versionTapCount = 0;
  DateTime? _debugTapStart;
  bool _debugUnlocked = false;
  bool get _showDebugHint => !kReleaseMode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _accountApi.getProfile(widget.owner),
        _accountApi.getSettings(widget.owner),
      ]);
      setState(() {
        _profile = results[0] as UserProfile;
        _settings = results[1] as AppSettings;
      });
    } catch (e) {
      setState(() {
        _error = formatErrorMessage(e);
      });
    } finally {
      final health = await _healthApi.checkHealth();
      if (mounted) {
        setState(() {
          _healthStatus = health;
          _loading = false;
        });
      }
    }
  }

  void _registerDebugTap() {
    final now = DateTime.now();
    if (_debugTapStart == null || now.difference(_debugTapStart!) > const Duration(seconds: 4)) {
      _debugTapStart = now;
      _debugTapCount = 0;
      _versionTapCount = 0;
    }
    _debugTapCount += 1;
    if (_debugTapCount >= 5) {
      _versionTapCount = 0;
    }
  }

  void _registerVersionTap() {
    if (_debugTapCount < 5) return;
    final now = DateTime.now();
    if (_debugTapStart == null || now.difference(_debugTapStart!) > const Duration(seconds: 6)) {
      _debugTapStart = null;
      _debugTapCount = 0;
      _versionTapCount = 0;
      return;
    }
      _versionTapCount += 1;
    if (_versionTapCount >= 3) {
      setState(() => _debugUnlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileDebugUnlocked)),
      );
    }
  }

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;

    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile),
      ),
    );

    if (updated != null) {
      setState(() => _profile = updated);
    }
  }

  Future<void> _changeDuoMode(bool enabled) async {
    widget.onModeChanged(enabled);
    try {
      final settings = await _accountApi.updateSettings(
        owner: widget.owner,
        duoEnabled: enabled,
      );
      setState(() => _settings = settings);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.profileModeSyncFailDetail(formatErrorMessage(e)),
          ),
        ),
      );
    }
  }

  Future<void> _changeNotificationMode(bool enabled) async {
    try {
      final settings = await _accountApi.updateSettings(
        owner: widget.owner,
        notificationsEnabled: enabled,
      );
      setState(() => _settings = settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppStrings.profileSettingFailDetail(formatErrorMessage(e)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: _buildTitleWithHealth(AppStrings.profileTitle)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildErrorPanel(_error!),
                ),
              GestureDetector(
                onTap: _registerDebugTap,
                child: _buildHeaderCard(profile),
              ),
              AppSpace.h16,
              if (widget.isGuest)
                _buildGuestLoginCard()
              else ...[
                _buildSectionTitle(
                  AppStrings.profileSectionInfoTitle,
                  AppStrings.profileSectionInfoSubtitle,
                ),
                AppSpace.h8,
                _buildInfoCard(profile),
                AppSpace.h12,
                _buildSectionTitle(
                  AppStrings.profileSectionAccountTitle,
                  AppStrings.profileSectionAccountSubtitle,
                ),
                AppSpace.h8,
                _buildAccountCard(settings),
                AppSpace.h12,
                _buildSectionTitle(
                  AppStrings.profileSectionSupportTitle,
                  AppStrings.profileSectionSupportSubtitle,
                ),
                AppSpace.h8,
                _buildSupportCard(),
              ],
              const SizedBox(height: AppSpace.lg + 2),
              GestureDetector(
                onTap: _registerVersionTap,
                child: const Text(
                  AppStrings.profileVersion,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.neutralStrong, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithHealth(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHealthDot(),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildHealthDot() {
    final status = _healthStatus;
    final online = status?.online == true;
    final color = status == null
        ? AppTheme.neutral
        : (online ? AppTheme.success : AppTheme.danger);
    return Icon(Icons.circle, size: 11, color: color);
  }

  Widget _buildHeaderCard(UserProfile? profile) {
    final preset = resolveAvatarPreset(profile?.avatar);
    return HeroPanel(
      tag: 'PROFILE',
      title: profile?.displayName ?? AppStrings.profileDefaultName,
      subtitle: AppStrings.profileOwnerId(
        profile?.owner ?? AppStrings.profileOwnerPlaceholder,
      ),
      trailing: CircleAvatar(
        radius: 18,
        backgroundColor: preset.bgColor.withValues(alpha: 0.5),
        child: Icon(preset.icon, color: preset.fgColor, size: 20),
      ),
      metrics: [
        HeroMetricData(
          icon: widget.duoEnabled
              ? Icons.people_alt_rounded
              : Icons.person_outline_rounded,
          label: AppStrings.profileModeLabel,
          value: widget.duoEnabled
              ? AppStrings.profileModeDuo
              : AppStrings.profileModeSolo,
        ),
        HeroMetricData(
          icon: widget.owner == 'me'
              ? Icons.person_pin_circle_rounded
              : Icons.handshake_rounded,
          label: AppStrings.profileOwnerLabel,
          value: widget.owner == 'me'
              ? AppStrings.profileOwnerMe
              : AppStrings.profileOwnerPartner,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        AppSpace.w10,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.sectionTitle),
            Text(subtitle, style: AppText.sectionSubtitle),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserProfile? profile) {
    return Container(
      decoration: AppSurface.card(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineItem(
            Icons.edit_rounded,
            AppStrings.profileEdit,
            profile?.displayName ?? AppStrings.profileLoading,
            onTap: _loading ? null : _editProfile,
          ),
          _buildDivider(),
          _buildInlineItem(
            Icons.people_alt_rounded,
            AppStrings.profileRelationship,
            AppStrings.profileRelationshipSubtitle,
            onTap: () async {
              final current = _profile;
              if (current == null) return;
              final updated = await Navigator.push<UserProfile>(
                context,
                MaterialPageRoute(
                  builder: (_) => RelationshipPage(profile: current),
                ),
              );
              if (updated != null && mounted) {
                setState(() => _profile = updated);
              }
            },
          ),
          _buildDivider(),
          _buildInlineSwitch(
            value: widget.duoEnabled,
            title: AppStrings.profileDuoMode,
            subtitle: widget.duoEnabled
                ? AppStrings.profileDuoModeOn
                : AppStrings.profileDuoModeOff,
            onChanged: _changeDuoMode,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AppSettings? settings) {
    return Container(
      decoration: AppSurface.card(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineItem(
            Icons.security_rounded,
            AppStrings.profileAccountSecurity,
            AppStrings.profileAccountSecuritySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AccountSecurityPage(owner: widget.owner),
              ),
            ),
          ),
          _buildDivider(),
          _buildInlineSwitch(
            value: settings?.notificationsEnabled ?? true,
            title: AppStrings.profileNotification,
            subtitle: AppStrings.profileNotificationSubtitle,
            onChanged: _changeNotificationMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Container(
      decoration: AppSurface.card(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInlineItem(
            Icons.feedback_rounded,
            AppStrings.profileHelp,
            AppStrings.profileHelpSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HelpFeedbackPage(owner: widget.owner),
              ),
            ),
          ),
          if (_showDebugHint && !_debugUnlocked) ...[
            _buildDivider(),
            _buildInlineHint(AppStrings.profileDebugHint),
          ],
          if (_debugUnlocked) ...[
            _buildDivider(),
            _buildInlineItem(
              Icons.bug_report_outlined,
              AppStrings.profileDebugTitle,
              AppStrings.profileDebugSubtitle,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DebugPage()),
                );
              },
            ),
          ],
          _buildDivider(),
          _buildInlineItem(
            Icons.privacy_tip_rounded,
            AppStrings.profilePrivacy,
            AppStrings.profilePrivacySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrivacyDataPage(owner: widget.owner),
              ),
            ),
          ),
          _buildDivider(),
          _buildInlineItem(
            Icons.info_outline_rounded,
            AppStrings.profileAbout,
            AppStrings.profileAboutSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          _buildDivider(),
          _buildInlineItem(
            Icons.logout_rounded,
            AppStrings.profileLogout,
            AppStrings.profileLogoutSubtitle,
            onTap: () async {
              final confirmed = await showModalBottomSheet<bool>(
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
                          AppStrings.profileLogoutTitle,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          AppStrings.profileLogoutHint,
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text(AppStrings.profileLogoutCancel),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(AppStrings.profileLogoutConfirm),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
              if (confirmed == true) {
                await widget.onLogout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInlineItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary),
      ),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text(subtitle, style: AppText.bodyMuted),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildInlineSwitch({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
          color: AppTheme.primary,
        ),
      ),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text(subtitle, style: AppText.bodyMuted),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInlineHint(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(text, style: AppText.bodyMuted),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, color: AppTheme.border);
  }

  Widget _buildGuestLoginCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppSurface.card(alpha: 0.98),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.profileGuestTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.profileGuestSubtitle,
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onExitGuest,
              child: const Text(AppStrings.profileGuestAction),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        border: Border.all(color: AppTheme.errorBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.profileErrorLoadingDetail(text),
              style: const TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
