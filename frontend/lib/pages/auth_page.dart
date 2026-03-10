import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated});

  final ValueChanged<String> onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);
  final _authApi = AuthApiService();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _inviteCode = TextEditingController();
  final _displayName = TextEditingController(text: '新用户');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    _inviteCode.dispose();
    _displayName.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loginByAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authApi.loginWithAccount(
        account: _account.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      widget.onAuthenticated(session.token);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerByAccount() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authApi.registerWithAccount(
        account: _account.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
        inviteCode: _inviteCode.text.trim(),
      );
      if (!mounted) return;
      widget.onAuthenticated(session.token);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.softBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PAIRTUNE AUTH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                AppSpace.h12,
                const Text(
                  '登录 PairTune',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                AppSpace.h8,
                const Text(
                  '先登录，再开始你的单人或双人协作。',
                  style: AppText.sectionSubtitle,
                ),
                AppSpace.h16,
                TabBar(
                  controller: _tab,
                  tabs: const [Tab(text: '登录'), Tab(text: '注册')],
                ),
                AppSpace.h12,
                if (_error != null) ...[
                  _buildErrorCard(_error!),
                  AppSpace.h8,
                ],
                SizedBox(
                  height: 420,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _AuthPanel(
                        title: '登录',
                        subtitle: '使用账号与密码登录',
                        primaryLabel: '账号登录',
                        loading: _loading,
                        accountController: _account,
                        passwordController: _password,
                        displayNameController: _displayName,
                        inviteCodeController: _inviteCode,
                        onPrimary: _loginByAccount,
                        showInvite: false,
                      ),
                      _AuthPanel(
                        title: '注册',
                        subtitle: '注册需要邀请码',
                        primaryLabel: '创建账号',
                        loading: _loading,
                        accountController: _account,
                        passwordController: _password,
                        displayNameController: _displayName,
                        inviteCodeController: _inviteCode,
                        onPrimary: _registerByAccount,
                        showInvite: true,
                      ),
                    ],
                  ),
                ),
                AppSpace.h12,
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => widget.onAuthenticated('dev_mode_token'),
                    child: const Text('先体验应用（游客模式）'),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        border: Border.all(color: AppTheme.errorBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '认证失败：$text',
        style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.loading,
    required this.accountController,
    required this.passwordController,
    required this.displayNameController,
    required this.inviteCodeController,
    required this.onPrimary,
    required this.showInvite,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final bool loading;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final TextEditingController inviteCodeController;
  final VoidCallback onPrimary;
  final bool showInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppSurface.card(alpha: 0.95, shadow: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.sectionTitle),
          AppSpace.h4,
          Text(subtitle, style: AppText.sectionSubtitle),
          AppSpace.h12,
          TextField(
            controller: displayNameController,
            enabled: !loading,
            decoration: const InputDecoration(
              labelText: '昵称',
              hintText: '输入昵称（可选）',
            ),
          ),
          AppSpace.h8,
          TextField(
            controller: accountController,
            enabled: !loading,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: '账号',
              hintText: '4-20位字母/数字/下划线',
            ),
          ),
          AppSpace.h8,
          TextField(
            controller: passwordController,
            enabled: !loading,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '至少6位',
            ),
          ),
          if (showInvite) ...[
            AppSpace.h8,
            TextField(
              controller: inviteCodeController,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: '邀请码',
                hintText: '请输入管理员提供的邀请码',
              ),
            ),
          ],
          AppSpace.h12,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onPrimary,
              icon: const Icon(Icons.login_rounded),
              label: Text(primaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
