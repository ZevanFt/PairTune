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
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController(text: '新用户');
  final _wechatCode = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _displayName.dispose();
    _wechatCode.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loginByPhone() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authApi.loginWithPhone(
        phone: _phone.text.trim(),
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

  Future<void> _registerByPhone() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.registerWithPhone(
        phone: _phone.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
      );
      final session = await _authApi.loginWithPhone(
        phone: _phone.text.trim(),
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

  Future<void> _loginByWechat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = await _authApi.loginWithWechatCode(
        code: _wechatCode.text.trim().isEmpty ? 'dev_wechat_code' : _wechatCode.text.trim(),
        displayName: _displayName.text.trim().isEmpty ? '微信用户' : _displayName.text.trim(),
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
                  height: 320,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _AuthPanel(
                        title: '登录',
                        subtitle: '可用：手机号登录、微信码登录（占位）',
                        primaryLabel: '微信码登录',
                        secondaryLabel: '手机号登录',
                        loading: _loading,
                        phoneController: _phone,
                        passwordController: _password,
                        displayNameController: _displayName,
                        wechatCodeController: _wechatCode,
                        onWechat: _loginByWechat,
                        onPhone: _loginByPhone,
                      ),
                      _AuthPanel(
                        title: '注册',
                        subtitle: '可用：手机号注册，注册后自动登录',
                        primaryLabel: '微信码注册',
                        secondaryLabel: '手机号注册',
                        loading: _loading,
                        phoneController: _phone,
                        passwordController: _password,
                        displayNameController: _displayName,
                        wechatCodeController: _wechatCode,
                        onWechat: _loginByWechat,
                        onPhone: _registerByPhone,
                      ),
                    ],
                  ),
                ),
                AppSpace.h12,
                Center(
                  child: TextButton(
                    onPressed: _loading ? null : () => widget.onAuthenticated('dev_mode_token'),
                    child: const Text('先体验应用（开发模式）'),
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
    required this.secondaryLabel,
    required this.loading,
    required this.phoneController,
    required this.passwordController,
    required this.displayNameController,
    required this.wechatCodeController,
    required this.onWechat,
    required this.onPhone,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final bool loading;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController displayNameController;
  final TextEditingController wechatCodeController;
  final VoidCallback onWechat;
  final VoidCallback onPhone;

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
            controller: phoneController,
            enabled: !loading,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: '手机号',
              hintText: '11位手机号',
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
          AppSpace.h8,
          TextField(
            controller: wechatCodeController,
            enabled: !loading,
            decoration: const InputDecoration(
              labelText: '微信 code（占位）',
              hintText: '留空会使用 dev_wechat_code',
            ),
          ),
          AppSpace.h12,
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: loading ? null : onWechat,
              icon: const Icon(Icons.chat_rounded),
              label: Text(primaryLabel),
            ),
          ),
          AppSpace.h8,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: loading ? null : onPhone,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
