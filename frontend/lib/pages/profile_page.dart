import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/backend_health.dart';
import '../providers/api_providers.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../ui/app_space.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/health_indicator.dart';
import '../widgets/section_header.dart';
import '../widgets/status_panel.dart';
import 'about_page.dart';
import 'account_security_page.dart';
import 'edit_profile_page.dart';
import 'help_feedback_page.dart';
import 'privacy_data_page.dart';
import 'relationship_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  BackendHealthStatus? _healthStatus;

  String get _owner => ref.read(appProvider).owner;
  bool get _isGuest => ref.read(isGuestProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHealth());
  }

  Future<void> _loadHealth() async {
    final health = await ref.read(healthApiProvider).checkHealth();
    if (mounted) setState(() => _healthStatus = health);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return AppScrollScaffold(
      appBar: AppBar(
        title: TitleWithHealth(
          title: '个人中心',
          status: _healthStatus ?? const BackendHealthStatus(online: false, statusCode: 0, statusText: '检查中'),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(themeProvider.notifier).cycle(),
            icon: Icon(ref.read(themeProvider.notifier).icon),
            tooltip: ref.read(themeProvider.notifier).displayName,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        // Guest banner
        if (_isGuest) ...[
          GuestBanner(onExit: () => ref.read(authProvider.notifier).exitGuest()),
          const SizedBox(height: AppSpace.md),
        ],

        // Profile card
        _ProfileCard(
          owner: appState.owner,
          duoEnabled: appState.duoEnabled,
          isGuest: _isGuest,
        ),
        const SizedBox(height: AppSpace.lg),

        // Settings sections
        const SectionHeader(title: '资料与关系', subtitle: '编辑资料并维护协作身份'),
        const SizedBox(height: AppSpace.sm),
        _SettingsGroup(items: [
          _SettingsItem(
            icon: Icons.edit_rounded,
            title: '编辑资料',
            subtitle: '完善头像、昵称与简介',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(owner: _owner))),
          ),
          _SettingsItem(
            icon: Icons.people_rounded,
            title: '关系管理',
            subtitle: '协作标签与偏好',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RelationshipPage(owner: _owner))),
          ),
          _SettingsItem(
            icon: Icons.group_work_rounded,
            title: '双人协作模式',
            subtitle: appState.duoEnabled ? '已开启：可切换我/搭档视角' : '已关闭：当前为单人模式',
            trailing: Switch(value: appState.duoEnabled, onChanged: (v) => _toggleDuoMode(v)),
          ),
        ]),
        const SizedBox(height: AppSpace.lg),

        const SectionHeader(title: '账号与通知', subtitle: '管理账号安全并调整消息提醒'),
        const SizedBox(height: AppSpace.sm),
        _SettingsGroup(items: [
          _SettingsItem(
            icon: Icons.shield_rounded,
            title: '账号安全',
            subtitle: '本地安全设置与检查',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AccountSecurityPage(owner: _owner))),
          ),
        ]),
        const SizedBox(height: AppSpace.lg),

        const SectionHeader(title: '支持与隐私', subtitle: '反馈问题并管理隐私数据'),
        const SizedBox(height: AppSpace.sm),
        _SettingsGroup(items: [
          _SettingsItem(
            icon: Icons.help_outline_rounded,
            title: '帮助与反馈',
            subtitle: '问题反馈与产品建议',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HelpFeedbackPage(owner: _owner))),
          ),
          _SettingsItem(
            icon: Icons.privacy_tip_rounded,
            title: '隐私与数据',
            subtitle: '导出数据、清理缓存',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PrivacyDataPage(owner: _owner))),
          ),
          _SettingsItem(
            icon: Icons.info_outline_rounded,
            title: '关于',
            subtitle: '作者与开源依赖说明',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
          ),
        ]),
        const SizedBox(height: AppSpace.lg),

        // Logout
        if (!_isGuest)
          FilledButton.tonal(
            onPressed: _confirmLogout,
            style: FilledButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('退出登录'),
          ),
      ],
    );
  }

  Future<void> _toggleDuoMode(bool enabled) async {
    try {
      await ref.read(accountApiProvider).updateSettings(owner: _owner, duoEnabled: enabled);
      ref.read(appProvider.notifier).setDuoEnabled(enabled);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模式同步失败：${formatErrorMessage(e)}')),
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后需要重新登录才能继续使用'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(appProvider.notifier).reset();
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ─── Profile Card ──────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.owner,
    required this.duoEnabled,
    required this.isGuest,
  });

  final String owner;
  final bool duoEnabled;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4F), Color(0xFF314772)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGuest ? '体验用户' : (owner == 'me' ? '我' : '搭档'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duoEnabled ? '双人协作模式' : '单人模式',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  duoEnabled ? '双人' : '单人',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Settings Group ────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 52),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: AppText.headline),
      subtitle: Text(subtitle, style: AppText.footnote.copyWith(color: AppTheme.textMuted)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      onTap: trailing != null ? null : onTap,
    );
  }
}
