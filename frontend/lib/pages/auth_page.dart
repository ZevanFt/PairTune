import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../utils/error_display.dart';
import '../widgets/status_panel.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated, required this.onGuest});

  final ValueChanged<String> onAuthenticated;
  final VoidCallback onGuest;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
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
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).loginWithAccount(account: _account.text.trim(), password: _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.authLoginTitle, style: AppText.title1),
                  const SizedBox(height: 8),
                  Text(AppStrings.authLoginSubtitle, style: AppText.bodyMuted()),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    ErrorPanel(message: '${AppStrings.authFailPrefix}${_error!}'),
                    const SizedBox(height: 12),
                  ],
                  _AuthFormCard(
                    title: AppStrings.authAccountPanelTitle,
                    subtitle: AppStrings.authAccountPanelSubtitle,
                    loading: _loading,
                    children: [
                      TextField(controller: _account, enabled: !_loading, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: AppStrings.authAccountLabel, hintText: AppStrings.authAccountHint)),
                      const SizedBox(height: 12),
                      TextField(controller: _password, enabled: !_loading, obscureText: true, decoration: const InputDecoration(labelText: AppStrings.authPasswordLabel, hintText: AppStrings.authPasswordHint)),
                      const SizedBox(height: 16),
                      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading ? null : _loginByAccount, icon: const Icon(Icons.login_rounded), label: const Text(AppStrings.authLoginButton))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(AppStrings.authNoAccount, style: AppText.bodyMuted()),
                    const SizedBox(width: 6),
                    TextButton(onPressed: _loading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text(AppStrings.authGoRegister)),
                  ]),
                  const SizedBox(height: 12),
                  Center(child: TextButton(onPressed: _loading ? null : widget.onGuest, child: const Text(AppStrings.authGuest))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({required this.title, required this.subtitle, required this.loading, required this.children});
  final String title;
  final String subtitle;
  final bool loading;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: AppSurface.card(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppText.headline),
        const SizedBox(height: 4),
        Text(subtitle, style: AppText.bodyMuted()),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
  }
}

// ─── Register Page ─────────────────────────────────────────────────────────

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _account = TextEditingController();
  final _password = TextEditingController();
  final _inviteCode = TextEditingController();
  final _displayName = TextEditingController(text: AppStrings.registerDefaultName);
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _account.dispose(); _password.dispose(); _inviteCode.dispose(); _displayName.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).registerWithAccount(
        account: _account.text.trim(), password: _password.text,
        displayName: _displayName.text.trim(), inviteCode: _inviteCode.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.registerSuccess)));
      }
    } catch (e) {
      if (mounted) setState(() => _error = formatErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_error != null) ...[ErrorPanel(message: '${AppStrings.registerFailPrefix}${_error!}'), const SizedBox(height: 12)],
                _AuthFormCard(title: AppStrings.registerPanelTitle, subtitle: AppStrings.registerPanelSubtitle, loading: _loading, children: [
                  TextField(controller: _displayName, enabled: !_loading, decoration: const InputDecoration(labelText: AppStrings.registerDisplayNameLabel, hintText: AppStrings.registerDisplayNameHint)),
                  const SizedBox(height: 12),
                  TextField(controller: _account, enabled: !_loading, keyboardType: TextInputType.text, decoration: const InputDecoration(labelText: AppStrings.registerAccountLabel, hintText: AppStrings.authAccountHint)),
                  const SizedBox(height: 12),
                  TextField(controller: _password, enabled: !_loading, obscureText: true, decoration: const InputDecoration(labelText: AppStrings.registerPasswordLabel, hintText: AppStrings.authPasswordHint)),
                  const SizedBox(height: 12),
                  TextField(controller: _inviteCode, enabled: !_loading, decoration: const InputDecoration(labelText: AppStrings.registerInviteLabel, hintText: AppStrings.registerInviteHint)),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _loading ? null : _register, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text(AppStrings.registerSubmit))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
