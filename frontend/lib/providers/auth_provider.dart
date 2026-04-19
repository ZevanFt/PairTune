import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';
import '../services/auth_api_service.dart';
import '../services/auth_session_store.dart';

/// Auth state sealed class for clean state modeling.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.token, required this.isGuest, this.session});
  final String token;
  final bool isGuest;
  final AuthSession? session;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.showIntro = false});
  final bool showIntro;
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

/// Notifier that manages the full auth lifecycle.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authApi, this._authStore) : super(const AuthInitial());

  final AuthApiService _authApi;
  final AuthSessionStore _authStore;
  static const _introKey = 'intro_seen';

  /// Restore session on app start.
  Future<void> restoreSession() async {
    state = const AuthLoading();
    final prefs = await SharedPreferences.getInstance();
    final seenIntro = prefs.getBool(_introKey) ?? false;
    final token = await _authStore.getToken();

    if (token == null || token.isEmpty) {
      state = AuthUnauthenticated(showIntro: !seenIntro);
      return;
    }

    try {
      final session = await _authApi.getSession(token);
      state = AuthAuthenticated(token: token, isGuest: false, session: session);
    } catch (_) {
      await _authStore.clearToken();
      state = AuthUnauthenticated(showIntro: !seenIntro);
    }
  }

  /// Login with account + password.
  Future<void> loginWithAccount({required String account, required String password}) async {
    state = const AuthLoading();
    try {
      final session = await _authApi.loginWithAccount(account: account, password: password);
      await _authStore.saveToken(session.token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introKey, true);
      state = AuthAuthenticated(token: session.token, isGuest: false, session: session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Register with account + password + invite code.
  Future<void> registerWithAccount({
    required String account,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    state = const AuthLoading();
    try {
      final session = await _authApi.registerWithAccount(
        account: account,
        password: password,
        displayName: displayName,
        inviteCode: inviteCode,
      );
      await _authStore.saveToken(session.token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introKey, true);
      state = AuthAuthenticated(token: session.token, isGuest: false, session: session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Enter guest mode.
  Future<void> enterGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
    state = const AuthAuthenticated(token: 'dev_mode_token', isGuest: true);
  }

  /// Dismiss intro, go to login.
  Future<void> dismissIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
    state = const AuthUnauthenticated(showIntro: false);
  }

  /// Logout.
  Future<void> logout() async {
    final current = state;
    if (current is AuthAuthenticated && !current.isGuest) {
      try {
        await _authApi.logout(current.token);
      } catch (_) {}
    }
    await _authStore.clearToken();
    state = const AuthUnauthenticated();
  }

  /// Exit guest mode.
  Future<void> exitGuest() async {
    await _authStore.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_introKey, true);
    state = const AuthUnauthenticated();
  }

  /// Reset to unauthenticated (e.g. after showing auth error).
  void resetToLogin() {
    state = const AuthUnauthenticated();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final authApiProvider = Provider((ref) => AuthApiService());
final authStoreProvider = Provider((ref) => AuthSessionStore());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authApiProvider), ref.watch(authStoreProvider));
});

/// Convenience selectors.
final isAuthenticatedProvider = Provider((ref) => ref.watch(authProvider) is AuthAuthenticated);
final isGuestProvider = Provider((ref) {
  final s = ref.watch(authProvider);
  return s is AuthAuthenticated && s.isGuest;
});
final authTokenProvider = Provider((ref) {
  final s = ref.watch(authProvider);
  return s is AuthAuthenticated ? s.token : null;
});
