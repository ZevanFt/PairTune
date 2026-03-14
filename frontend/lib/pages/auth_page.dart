import 'package:flutter/material.dart';

import '../i18n/app_strings.dart';
import '../services/auth_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated, required this.onGuest});

  final ValueChanged<String> onAuthenticated;
  final VoidCallback onGuest;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _authApi = AuthApiService();
  final _account = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.authLoginTitle,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                      ),
                    ),
                    AppSpace.h8,
                    const Text(AppStrings.authLoginSubtitle, style: AppText.sectionSubtitle),
                    AppSpace.h12,
                    if (_error != null) ...[
                      _buildErrorCard(_error!),
                      AppSpace.h8,
                    ],
                    _AuthPanel(
                      title: AppStrings.authAccountPanelTitle,
                      subtitle: AppStrings.authAccountPanelSubtitle,
                      primaryLabel: AppStrings.authLoginButton,
                      loading: _loading,
                      accountController: _account,
                      passwordController: _password,
                      onPrimary: _loginByAccount,
                    ),
                    AppSpace.h8,
                    Row(
                      children: [
                        Text(
                          AppStrings.authNoAccount,
                          style: AppText.sectionSubtitle,
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterPage(onGuest: widget.onGuest),
                                    ),
                                  ),
                          child: const Text(AppStrings.authGoRegister),
                        ),
                      ],
                    ),
                    AppSpace.h8,
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : widget.onGuest,
                        child: const Text(AppStrings.authGuest),
                      ),
                    ),
                  ],
                ),
              ),
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
        '${AppStrings.authFailPrefix}$text',
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
    required this.onPrimary,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final bool loading;
  final TextEditingController accountController;
  final TextEditingController passwordController;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: AppSurface.card(alpha: 0.98, shadow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.sectionTitle),
          AppSpace.h4,
          Text(subtitle, style: AppText.sectionSubtitle),
          AppSpace.h12,
          TextField(
            controller: accountController,
            enabled: !loading,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: AppStrings.authAccountLabel,
              hintText: AppStrings.authAccountHint,
            ),
          ),
          AppSpace.h8,
          TextField(
            controller: passwordController,
            enabled: !loading,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.authPasswordLabel,
              hintText: AppStrings.authPasswordHint,
            ),
          ),
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

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.onGuest});

  final VoidCallback? onGuest;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _authApi = AuthApiService();
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _inviteCode = TextEditingController();
  final _displayName = TextEditingController(text: AppStrings.registerDefaultName);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    _inviteCode.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authApi.registerWithAccount(
        account: _account.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim(),
        inviteCode: _inviteCode.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.registerSuccess)),
      );
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
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null) ...[
                      _buildRegisterErrorCard(_error!),
                      AppSpace.h8,
                    ],
                    Container(
                      padding: const EdgeInsets.all(AppSpace.md),
                      decoration: AppSurface.card(alpha: 0.98, shadow: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.registerPanelTitle, style: AppText.sectionTitle),
                          AppSpace.h4,
                          const Text(AppStrings.registerPanelSubtitle, style: AppText.sectionSubtitle),
                          AppSpace.h12,
                          TextField(
                            controller: _displayName,
                            enabled: !_loading,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerDisplayNameLabel,
                              hintText: AppStrings.registerDisplayNameHint,
                            ),
                          ),
                          AppSpace.h8,
                          TextField(
                            controller: _account,
                            enabled: !_loading,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerAccountLabel,
                              hintText: AppStrings.authAccountHint,
                            ),
                          ),
                          AppSpace.h8,
                          TextField(
                            controller: _password,
                            enabled: !_loading,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerPasswordLabel,
                              hintText: AppStrings.authPasswordHint,
                            ),
                          ),
                          AppSpace.h8,
                          TextField(
                            controller: _inviteCode,
                            enabled: !_loading,
                            decoration: const InputDecoration(
                              labelText: AppStrings.registerInviteLabel,
                              hintText: AppStrings.registerInviteHint,
                            ),
                          ),
                          AppSpace.h12,
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _loading ? null : _register,
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text(AppStrings.registerSubmit),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpace.h12,
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : widget.onGuest,
                        child: const Text(AppStrings.authGuest),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterErrorCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        border: Border.all(color: AppTheme.errorBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${AppStrings.registerFailPrefix}$text',
        style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
