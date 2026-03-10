import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'pages/store_page.dart';
import 'services/auth_api_service.dart';
import 'services/auth_session_store.dart';
import 'ui/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PriorityFirstApp());
}

class PriorityFirstApp extends StatelessWidget {
  const PriorityFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '合拍 PairTune',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _RootPage(),
    );
  }
}

class _RootPage extends StatefulWidget {
  const _RootPage();

  @override
  State<_RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<_RootPage> {
  int _index = 0;
  String _owner = 'me';
  bool _authLoading = true;
  bool _authed = false;
  String? _authToken;
  bool? _duoEnabled;
  final _authApi = AuthApiService();
  final _authStore = AuthSessionStore();

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _authStore.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() => _authLoading = false);
      return;
    }
    try {
      await _authApi.getSession(token);
      if (!mounted) return;
      setState(() {
        _authToken = token;
        _authed = true;
        _authLoading = false;
      });
    } catch (_) {
      await _authStore.clearToken();
      if (!mounted) return;
      setState(() {
        _authToken = null;
        _authed = false;
        _authLoading = false;
      });
    }
  }

  Future<void> _handleAuthenticated(String token) async {
    if (token.isNotEmpty && token != 'dev_mode_token') {
      await _authStore.saveToken(token);
    }
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _authed = true;
    });
  }

  Future<void> _handleLogout() async {
    final token = _authToken;
    if (token != null && token.isNotEmpty && token != 'dev_mode_token') {
      try {
        await _authApi.logout(token);
      } catch (_) {
        // Ignore remote logout failure; local sign-out still proceeds.
      }
    }
    await _authStore.clearToken();
    if (!mounted) return;
    setState(() {
      _authed = false;
      _authToken = null;
      _duoEnabled = null;
      _owner = 'me';
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_authed) {
      return AuthPage(
        onAuthenticated: _handleAuthenticated,
      );
    }

    if (_duoEnabled == null) {
      return _ModeSelectPage(
        onSelected: (duoEnabled) {
          setState(() {
            _duoEnabled = duoEnabled;
            _owner = 'me';
            _index = 0;
          });
        },
      );
    }

    final pages = [
      HomePage(
        owner: _owner,
        duoEnabled: _duoEnabled!,
        onOwnerChanged: (owner) => setState(() => _owner = owner),
      ),
      StorePage(
        owner: _owner,
        duoEnabled: _duoEnabled!,
        onOwnerChanged: (owner) => setState(() => _owner = owner),
      ),
      NotificationsPage(owner: _owner),
      ProfilePage(
        owner: _owner,
        duoEnabled: _duoEnabled!,
        onModeChanged: (duoEnabled) {
          setState(() {
            _duoEnabled = duoEnabled;
            _owner = 'me';
          });
        },
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _BrandBottomBar(
        index: _index,
        onChanged: (index) => setState(() => _index = index),
      ),
    );
  }
}

class _ModeSelectPage extends StatelessWidget {
  const _ModeSelectPage({required this.onSelected});

  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    'PAIR MODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '合拍 PairTune',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '一个人也能用，两个人更好用。',
                  style: TextStyle(fontSize: 16, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 28),
                _modeCard(
                  title: '先单人开始',
                  subtitle: '独立管理任务和积分，后续可随时升级双人协作',
                  icon: Icons.person_rounded,
                  onTap: () => onSelected(false),
                ),
                const SizedBox(height: 12),
                _modeCard(
                  title: '邀请搭档一起',
                  subtitle: '开启双人视角、协作提醒与奖励互动',
                  icon: Icons.people_alt_rounded,
                  onTap: () => onSelected(true),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppTheme.primary.withValues(alpha: 0.08);
          }
          return null;
        }),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandBottomBar extends StatelessWidget {
  const _BrandBottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppTheme.panel,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: selected ? AppTheme.primary : AppTheme.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTheme.primary : AppTheme.textMuted,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: index,
        height: 66,
        onDestinationSelected: onChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: '任务',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag_rounded),
            label: '商城',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: '通知',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: '个人',
          ),
        ],
      ),
    );
  }
}
