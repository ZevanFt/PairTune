import 'package:flutter/material.dart';

import '../services/account_api_service.dart';
import '../services/health_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import 'debug_page.dart';

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

    final controller = TextEditingController(text: profile.displayName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDialogShell(
        title: '编辑昵称',
        subtitle: '用于任务、通知与协作展示',
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final next = await _accountApi.updateProfile(
        owner: widget.owner,
        displayName: controller.text.trim().isEmpty
            ? profile.displayName
            : controller.text.trim(),
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

  Widget _buildDialogShell({
    required String title,
    required String subtitle,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: const Color(0xFFFFFCF8),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      contentPadding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      content: content,
      actions: actions,
    );
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
    final ownerName = widget.owner == 'me' ? '我' : '搭档';

    return Scaffold(
      appBar: AppBar(title: _buildTitleWithHealth('我的 · $ownerName')),
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
              _buildSectionTitle('资料与关系', '管理个人资料与双人协作身份'),
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
              _buildSectionTitle('账号与通知', '控制账号安全与消息推送行为'),
              const SizedBox(height: 8),
              _buildItem(Icons.security_rounded, '账号安全', '手机号/邮箱/登录方式'),
              _buildSwitchCard(
                value: settings?.notificationsEnabled ?? true,
                title: '通知开关',
                subtitle: '任务提醒与商城提醒',
                onChanged: _changeNotificationMode,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('支持与隐私', '反馈、调试与数据相关能力'),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2B4F), Color(0xFF304778), Color(0xFF3D588F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A2A3B5E),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFE8F1FF),
            child: Icon(Icons.person_rounded, color: Color(0xFF1A2B4F), size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x2BFFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PROFILE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile?.displayName ?? '合拍用户',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'PairTune ID: ${profile?.owner ?? '...'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
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
        color: Colors.white.withValues(alpha: 0.92),
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
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
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
