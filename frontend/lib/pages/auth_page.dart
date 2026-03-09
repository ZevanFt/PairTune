import 'package:flutter/material.dart';

import '../ui/app_space.dart';
import '../ui/app_surface.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
                SizedBox(
                  height: 236,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _AuthPanel(
                        title: '登录',
                        subtitle: '支持微信登录 / 手机号登录（后续接入）',
                        primaryLabel: '微信登录（待接入）',
                        secondaryLabel: '手机号登录（待接入）',
                        onContinue: widget.onAuthenticated,
                      ),
                      _AuthPanel(
                        title: '注册',
                        subtitle: '支持手机号注册与微信快捷注册（后续接入）',
                        primaryLabel: '微信注册（待接入）',
                        secondaryLabel: '手机号注册（待接入）',
                        onContinue: widget.onAuthenticated,
                      ),
                    ],
                  ),
                ),
                AppSpace.h12,
                Center(
                  child: TextButton(
                    onPressed: widget.onAuthenticated,
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
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onContinue;

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
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.wechat_rounded),
              label: Text(primaryLabel),
            ),
          ),
          AppSpace.h8,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.phone_iphone_rounded),
              label: Text(secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

