import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error.dart';
import 'api_logger.dart';

class UserProfile {
  UserProfile({
    required this.owner,
    required this.displayName,
    this.bio,
    this.avatar,
    required this.relationshipLabel,
  });

  final String owner;
  final String displayName;
  final String? bio;
  final String? avatar;
  final String relationshipLabel;

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      owner: map['owner'] as String,
      displayName: map['display_name'] as String,
      bio: map['bio'] as String?,
      avatar: map['avatar'] as String?,
      relationshipLabel: (map['relationship_label'] as String?) ?? '搭档',
    );
  }
}

class AppSettings {
  AppSettings({
    required this.owner,
    required this.duoEnabled,
    required this.notificationsEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final String owner;
  final bool duoEnabled;
  final bool notificationsEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  static AppSettings fromMap(Map<String, dynamic> map) {
    return AppSettings(
      owner: map['owner'] as String,
      duoEnabled: ((map['duo_enabled'] as num?) ?? 0).toInt() == 1,
      notificationsEnabled:
          ((map['notifications_enabled'] as num?) ?? 1).toInt() == 1,
      quietHoursStart: map['quiet_hours_start'] as String?,
      quietHoursEnd: map['quiet_hours_end'] as String?,
    );
  }
}

class NoticeItem {
  NoticeItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  static NoticeItem fromMap(Map<String, dynamic> map) {
    return NoticeItem(
      id: (map['id'] as num).toInt(),
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: ((map['is_read'] as num?) ?? 0).toInt() == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class AccountApiService {
  AccountApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<UserProfile> getProfile(String owner) async {
    const path = '/profile';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('AccountApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserProfile.fromMap(data['result'] as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required String owner,
    required String displayName,
    String? bio,
    String? avatar,
    String relationshipLabel = '搭档',
  }) async {
    const path = '/profile';
    final uri = _uri(path);
    final payload = {
      'owner': owner,
      'display_name': displayName,
      'bio': bio,
      'avatar': avatar,
      'relationship_label': relationshipLabel,
    };
    ApiLogger.request('AccountApi', 'PUT', uri, body: jsonEncode(payload));
    final resp = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserProfile.fromMap(data['result'] as Map<String, dynamic>);
  }

  Future<AppSettings> getSettings(String owner) async {
    const path = '/settings';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('AccountApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AppSettings.fromMap(data['result'] as Map<String, dynamic>);
  }

  Future<AppSettings> updateSettings({
    required String owner,
    bool? duoEnabled,
    bool? notificationsEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    final body = <String, dynamic>{'owner': owner};
    if (duoEnabled != null) body['duo_enabled'] = duoEnabled;
    if (notificationsEnabled != null) {
      body['notifications_enabled'] = notificationsEnabled;
    }
    if (quietHoursStart != null) body['quiet_hours_start'] = quietHoursStart;
    if (quietHoursEnd != null) body['quiet_hours_end'] = quietHoursEnd;

    const path = '/settings';
    final uri = _uri(path);
    ApiLogger.request('AccountApi', 'PUT', uri, body: jsonEncode(body));
    final resp = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return AppSettings.fromMap(data['result'] as Map<String, dynamic>);
  }

  Future<(List<NoticeItem>, int)> listNotifications(
    String owner, {
    String status = 'all',
  }) async {
    const path = '/notifications';
    final uri = _uri('$path?owner=$owner&status=$status&limit=50');
    ApiLogger.request('AccountApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    final list = (result['list'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(NoticeItem.fromMap)
        .toList();
    final unreadCount = (result['unread_count'] as num).toInt();
    return (list, unreadCount);
  }

  Future<void> markNotificationRead({
    required String owner,
    required int id,
  }) async {
    const path = '/notifications/mark-read';
    final uri = _uri(path);
    final payload = {'owner': owner, 'id': id};
    ApiLogger.request('AccountApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<void> markAllNotificationsRead(String owner) async {
    const path = '/notifications/mark-all-read';
    final uri = _uri(path);
    final payload = {'owner': owner};
    ApiLogger.request('AccountApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('AccountApi', uri, resp);
    _ensureOk(resp, path);
  }
}
