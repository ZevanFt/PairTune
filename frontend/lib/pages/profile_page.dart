import 'package:flutter/material.dart';

import '../services/account_api_service.dart';
import '../services/health_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/hero_panel.dart';
import 'debug_page.dart';
import 'edit_display_name_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.owner,
    required this.duoEnabled,
    required this.onModeChanged,
  });

  final String owner;
  final bool duoEnabled;
  final ValueChanged<bool> onModeChanged;

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

  Future<void> _editDisplayName() async {
    final profile = _profile;
    if (profile == null) return;

    final nextName = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditDisplayNamePage(
          initialName: profile.displayName,
        ),
      ),
    );

    if (nextName == null || nextName.trim().isEmpty) return;

    try {
      final next = await _accountApi.updateProfile(
        owner: widget.owner,
        displayName: nextName.trim(),
        bio: profile.bio,
        avatar: profile.avatar,
        relationshipLabel: profile.relationshipLabel,
      );
      setState(() => _profile = next);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('昵称已更新')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: ${formatErrorMessage(e)}')),
        );
      }
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
        SnackBar(content: Text('模式同步失败: ${formatErrorMessage(e)}')),
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
          SnackBar(content: Text('设置失败: ${formatErrorMessage(e)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final settings = _settings;

    return Scaffold(
      appBar: AppBar(title: _buildTitleWithHealth('个人中心')),
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
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildErrorPanel(_error!),
                ),
              _buildHeaderCard(profile),
              const SizedBox(height: 16),
              _buildSectionTitle('资料与关系', '编辑资料并维护协作身份'),
              const SizedBox(height: 8),
              _buildItem(
                Icons.edit_rounded,
                '编辑资料',
                profile?.displayName ?? '加载中...',
                onTap: _loading ? null : _editDisplayName,
              ),
              _buildItem(Icons.people_alt_rounded, '关系管理', '对象/闺蜜/室友/搭子'),
              _buildSwitchCard(
                value: widget.duoEnabled,
                title: '双人协作模式',
                subtitle: widget.duoEnabled ? '已开启：可切换我/搭档视角' : '已关闭：当前为单人模式',
                onChanged: _changeDuoMode,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('账号与通知', '管理账号安全并调整消息提醒'),
              const SizedBox(height: 8),
              _buildItem(Icons.security_rounded, '账号安全', '手机号/邮箱/登录方式'),
              _buildSwitchCard(
                value: settings?.notificationsEnabled ?? true,
                title: '通知开关',
                subtitle: '任务提醒与商城提醒',
                onChanged: _changeNotificationMode,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('支持与隐私', '反馈问题并管理隐私数据'),
              const SizedBox(height: 8),
              _buildItem(Icons.feedback_rounded, '帮助与反馈', '问题反馈与产品建议'),
              _buildItem(
                Icons.bug_report_outlined,
                '调试页面',
                '查看 API 日志并运行网络诊断',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebugPage()),
                  );
                },
              ),
              _buildItem(Icons.privacy_tip_rounded, '隐私与数据', '导出数据、账号注销'),
              const SizedBox(height: 18),
              Text(
                '合拍 PairTune · v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
        ? Colors.grey
        : (online ? AppTheme.success : AppTheme.danger);
    return Icon(Icons.circle, size: 11, color: color);
  }

  Widget _buildHeaderCard(UserProfile? profile) {
    return HeroPanel(
      tag: 'PROFILE',
      title: profile?.displayName ?? '合拍用户',
      subtitle: 'PairTune ID: ${profile?.owner ?? '...'}',
      trailing: const CircleAvatar(
        radius: 18,
        backgroundColor: Color(0x33FFFFFF),
        child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
      ),
      metrics: [
        HeroMetricData(
          icon: widget.duoEnabled
              ? Icons.people_alt_rounded
              : Icons.person_outline_rounded,
          label: '当前模式',
          value: widget.duoEnabled ? '双人' : '单人',
        ),
        HeroMetricData(
          icon: widget.owner == 'me'
              ? Icons.person_pin_circle_rounded
              : Icons.handshake_rounded,
          label: '当前身份',
          value: widget.owner == 'me' ? '我' : '搭档',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchCard({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: SwitchListTile(
        value: value,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.softBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
              '加载失败：$text',
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
