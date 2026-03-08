import 'package:flutter/material.dart';

import 'pages/home_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'pages/store_page.dart';
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
  bool? _duoEnabled;

  @override
  Widget build(BuildContext context) {
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
                    color: Color(0xFF1A2B4F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '一个人也能用，两个人更好用。',
                  style: TextStyle(fontSize: 16, color: Color(0xFF4A5672)),
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1A2B4F)),
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
                        color: Color(0xFF1A2B4F),
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
    final items = const [
      (Icons.check_circle_outline_rounded, '任务'),
      (Icons.storefront_rounded, '商城'),
      (Icons.notifications_none_rounded, '通知'),
      (Icons.person_outline_rounded, '我的'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.panel.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.panelBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A1D2A44),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == index;
            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.softBlue : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.only(bottom: 5),
                          height: 2.5,
                          width: selected ? 22 : 0,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Icon(
                          items[i].$1,
                          size: selected ? 22 : 21,
                          color: selected
                              ? const Color(0xFF1A2B4F)
                              : const Color(0xFF8A93A5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 11.5,
                            letterSpacing: 0.15,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected
                                ? const Color(0xFF1A2B4F)
                                : const Color(0xFF8A93A5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
