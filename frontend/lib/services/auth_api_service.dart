import '../models/auth_session.dart';
import 'api_base.dart';

class AuthApiService extends ApiBase {
  AuthApiService({super.client});

  @override
  String get tag => 'Auth';

  Future<AuthSession> registerWithAccount({
    required String account,
    required String password,
    required String displayName,
    required String inviteCode,
  }) async {
    final data = await post('/auth/register/account', {
      'account': account,
      'password': password,
      'display_name': displayName,
      'invite_code': inviteCode,
    });
    return AuthSession.fromMap(ApiBase.result(data));
  }

  Future<AuthSession> loginWithAccount({
    required String account,
    required String password,
  }) async {
    final data = await post('/auth/login/account', {
      'account': account,
      'password': password,
    });
    return AuthSession.fromMap(ApiBase.result(data));
  }

  Future<void> logout(String token) async {
    await postVoid('/auth/logout', {'token': token});
  }

  Future<AuthSession> getSession(String token) async {
    final data = await get('/auth/session?token=$token');
    return AuthSession.fromMap(ApiBase.result(data));
  }
}
