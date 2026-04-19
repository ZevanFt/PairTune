class AuthSession {
  AuthSession({
    required this.token,
    required this.provider,
    required this.expiresAt,
    required this.userId,
    required this.displayName,
    this.phone,
    this.email,
    this.account,
    this.role,
    this.wechatOpenid,
  });

  final String token;
  final String provider;
  final DateTime expiresAt;
  final int userId;
  final String displayName;
  final String? phone;
  final String? email;
  final String? account;
  final String? role;
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
      email: user['email'] as String?,
      account: user['account'] as String?,
      role: user['role'] as String?,
      wechatOpenid: user['wechat_openid'] as String?,
    );
  }
}
