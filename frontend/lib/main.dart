import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'i18n/app_strings.dart';
import 'pages/auth_page.dart';
import 'pages/home_page.dart';
import 'pages/intro_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'pages/store_page.dart';
import 'providers/app_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'ui/app_theme.dart';
import 'ui/app_text.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
  );
  runApp(const ProviderScope(child: PriorityFirstApp()));
}

class PriorityFirstApp extends ConsumerWidget {
  const PriorityFirstApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authProvider);

    // Restore session on first build
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev is AuthInitial && next is AuthLoading) return;
      if (prev is AuthInitial && next is! AuthLoading) {
        // Already restored or needs restore
      }
    });

    // Auto-restore session if still in initial state
    if (authState is AuthInitial) {
      Future.microtask(() => ref.read(authProvider.notifier).restoreSession());
    }

    final router = _createRouter(ref, authState);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }

  GoRouter _createRouter(WidgetRef ref, AuthState authState) {
    final isAuthed = authState is AuthAuthenticated;
    final isGuest = authState is AuthAuthenticated && authState.isGuest;
    final appState = ref.read(appProvider);

    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final isAuthRoute = state.matchedLocation == '/auth' || state.matchedLocation == '/intro';

        if (!isAuthed && !isAuthRoute) {
          if (authState is AuthUnauthenticated && authState.showIntro) return '/intro';
          return '/auth';
        }
        if (isAuthed && isAuthRoute) return '/';
        if (isAuthed && !appState.duoModeSelected && !isGuest) return '/mode-select';
        return null;
      },
      routes: [
        GoRoute(path: '/intro', builder: (context, state) => IntroPage(
          onLogin: () => ref.read(authProvider.notifier).dismissIntro(),
          onGuest: () => ref.read(authProvider.notifier).enterGuest(),
        )),
        GoRoute(path: '/auth', builder: (context, state) => AuthPage(
          onAuthenticated: (token) {}, // handled by provider
          onGuest: () => ref.read(authProvider.notifier).enterGuest(),
        )),
        GoRoute(path: '/mode-select', builder: (context, state) => _ModeSelectPage(
          onSelected: (duoEnabled) {
            if (duoEnabled) {
              ref.read(appProvider.notifier).selectDuoMode();
            } else {
              ref.read(appProvider.notifier).selectSoloMode();
            }
            context.go('/');
          },
        )),
        ShellRoute(
          builder: (context, state, child) => _MainShell(child: child, isGuest: isGuest),
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
            GoRoute(path: '/store', builder: (context, state) => const StorePage()),
            GoRoute(path: '/notifications', builder: (context, state) => const NotificationsPage()),
            GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
          ],
        ),
      ],
    );
  }
}

// ─── Main Shell with Bottom Navigation ─────────────────────────────────────

class _MainShell extends ConsumerWidget {
  const _MainShell({required this.child, required this.isGuest});

  final Widget child;
  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appProvider);
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location == '/store') currentIndex = 1;
    else if (location == '/notifications') currentIndex = 2;
    else if (location == '/profile') currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        height: 64,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/store');
            case 2: context.go('/notifications');
            case 3: context.go('/profile');
          }
        },
        destinations: isGuest
            ? const [
                NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded), label: '任务'),
                NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: '商城'),
              ]
            : const [
                NavigationDestination(icon: Icon(Icons.check_circle_outline_rounded), selectedIcon: Icon(Icons.check_circle_rounded), label: '任务'),
                NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: '商城'),
                NavigationDestination(icon: Icon(Icons.notifications_none_rounded), selectedIcon: Icon(Icons.notifications_rounded), label: '通知'),
                NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: '个人'),
              ],
      ),
    );
  }
}

// ─── Mode Select Page ──────────────────────────────────────────────────────

class _ModeSelectPage extends StatelessWidget {
  const _ModeSelectPage({required this.onSelected});

  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                  AppStrings.modeTag,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.1),
                ),
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.modeTitle, style: AppText.title1),
              const SizedBox(height: 8),
              Text(AppStrings.modeSubtitle, style: AppText.bodyMuted()),
              const SizedBox(height: 28),
              _modeCard(
                title: AppStrings.modeSoloTitle,
                subtitle: AppStrings.modeSoloSubtitle,
                icon: Icons.person_rounded,
                onTap: () => onSelected(false),
              ),
              const SizedBox(height: 12),
              _modeCard(
                title: AppStrings.modeDuoTitle,
                subtitle: AppStrings.modeDuoSubtitle,
                icon: Icons.people_alt_rounded,
                onTap: () => onSelected(true),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: AppTheme.softBlue, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.ink)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: AppText.bodyMuted()),
                ],
              )),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
