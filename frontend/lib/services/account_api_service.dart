import '../models/app_settings.dart';
import '../models/notice_item.dart';
import '../models/user_profile.dart';
import 'api_base.dart';

class AccountApiService extends ApiBase {
  AccountApiService({super.client});

  @override
  String get tag => 'Account';

  Future<UserProfile> getProfile(String owner) async {
    final data = await get('/profile?owner=$owner');
    return UserProfile.fromMap(ApiBase.result(data));
  }

  Future<UserProfile> updateProfile({
    required String owner,
    required String displayName,
    String? bio,
    String? avatar,
    String relationshipLabel = '搭档',
  }) async {
    final data = await put('/profile', {
      'owner': owner,
      'display_name': displayName,
      'bio': bio,
      'avatar': avatar,
      'relationship_label': relationshipLabel,
    });
    return UserProfile.fromMap(ApiBase.result(data));
  }

  Future<AppSettings> getSettings(String owner) async {
    final data = await get('/settings?owner=$owner');
    return AppSettings.fromMap(ApiBase.result(data));
  }

  Future<AppSettings> updateSettings({
    required String owner,
    bool? duoEnabled,
    bool? notificationsEnabled,
    bool? relationCheckin,
    bool? relationReminder,
    bool? relationCoopHint,
    bool? securityLoginAlert,
    bool? securityRiskGuard,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) async {
    final body = <String, dynamic>{'owner': owner};
    if (duoEnabled != null) body['duo_enabled'] = duoEnabled;
    if (notificationsEnabled != null) body['notifications_enabled'] = notificationsEnabled;
    if (relationCheckin != null) body['relation_checkin'] = relationCheckin;
    if (relationReminder != null) body['relation_reminder'] = relationReminder;
    if (relationCoopHint != null) body['relation_coop_hint'] = relationCoopHint;
    if (securityLoginAlert != null) body['security_login_alert'] = securityLoginAlert;
    if (securityRiskGuard != null) body['security_risk_guard'] = securityRiskGuard;
    if (quietHoursStart != null) body['quiet_hours_start'] = quietHoursStart;
    if (quietHoursEnd != null) body['quiet_hours_end'] = quietHoursEnd;

    final data = await put('/settings', body);
    return AppSettings.fromMap(ApiBase.result(data));
  }

  Future<(List<NoticeItem>, int)> listNotifications(String owner, {String status = 'all'}) async {
    final data = await get('/notifications?owner=$owner&status=$status&limit=50');
    final result = ApiBase.result(data);
    final list = (result['list'] as List).cast<Map<String, dynamic>>().map(NoticeItem.fromMap).toList();
    final unreadCount = (result['unread_count'] as num).toInt();
    return (list, unreadCount);
  }

  Future<void> markNotificationRead({required String owner, required int id}) async {
    await postVoid('/notifications/mark-read', {'owner': owner, 'id': id});
  }

  Future<void> markAllNotificationsRead(String owner) async {
    await postVoid('/notifications/mark-all-read', {'owner': owner});
  }
}
