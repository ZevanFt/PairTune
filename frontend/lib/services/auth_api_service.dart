import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error.dart';
import 'api_logger.dart';

class AuthSession {
  AuthSession({
    required this.token,
    required this.provider,
    required this.expiresAt,
    required this.userId,
    required this.displayName,
    this.phone,
    this.wechatOpenid,
  });

  final String token;
  final String provider;
  final DateTime expiresAt;
  final int userId;
  final String displayName;
  final String? phone;
  final String? wechatOpenid;

  static AuthSession fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>;
    return AuthSession(
      token: map['token'] as String,
      provider: map['provider'] as String,
      expiresAt: DateTime.parse(map['expires_at'] as String),
      userId: (user['id'] as num).toInt(),
      displayName: user['display_name'] as String? ?? '用户',
      phone: user['phone'] as String?,
      wechatOpenid: user['wechat_openid'] as String?,
    );
  }
}

class AuthApiService {
  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  void _ensureOk(http.Response resp, String path) {
    if (resp.statusCode != 200) {
      throw ApiHttpError(
        statusCode: resp.statusCode,
        statusText: ApiLogger.messageFromResponse(resp),
        endpoint: path,
      );
    }
  }

  Future<void> registerWithPhone({
    required String phone,
    required String password,
    required String displayName,
  }) async {
    const path = '/auth/register/phone';
    final uri = _uri(path);
    final payload = {
      'phone': phone,
      'password': password,
      'display_name': displayName,
    };
    ApiLogger.request('AuthApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AuthApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<AuthSession> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    const path = '/auth/login/phone';
    final uri = _uri(path);
    final payload = {'phone': phone, 'password': password};
    ApiLogger.request('AuthApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AuthApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AuthSession.fromMap((data['result'] as Map<String, dynamic>));
  }

  Future<AuthSession> loginWithWechatCode({
    required String code,
    required String displayName,
  }) async {
    const path = '/auth/login/wechat';
    final uri = _uri(path);
    final payload = {'wechat_code': code, 'display_name': displayName};
    ApiLogger.request('AuthApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AuthApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AuthSession.fromMap((data['result'] as Map<String, dynamic>));
  }

  Future<void> logout(String token) async {
    const path = '/auth/logout';
    final uri = _uri(path);
    final payload = {'token': token};
    ApiLogger.request('AuthApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AuthApi', uri, resp);
    _ensureOk(resp, path);
  }
}

