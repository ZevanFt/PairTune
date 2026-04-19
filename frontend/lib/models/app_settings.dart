class AppSettings {
  AppSettings({
    required this.owner,
    required this.duoEnabled,
    required this.notificationsEnabled,
    required this.relationCheckin,
    required this.relationReminder,
    required this.relationCoopHint,
    required this.securityLoginAlert,
    required this.securityRiskGuard,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final String owner;
  final bool duoEnabled;
  final bool notificationsEnabled;
  final bool relationCheckin;
  final bool relationReminder;
  final bool relationCoopHint;
  final bool securityLoginAlert;
  final bool securityRiskGuard;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  static AppSettings fromMap(Map<String, dynamic> map) {
    return AppSettings(
      owner: map['owner'] as String,
      duoEnabled: ((map['duo_enabled'] as num?) ?? 0).toInt() == 1,
      notificationsEnabled:
          ((map['notifications_enabled'] as num?) ?? 1).toInt() == 1,
      relationCheckin: ((map['relation_checkin'] as num?) ?? 1).toInt() == 1,
      relationReminder: ((map['relation_reminder'] as num?) ?? 1).toInt() == 1,
      relationCoopHint: ((map['relation_coop_hint'] as num?) ?? 1).toInt() == 1,
      securityLoginAlert: ((map['security_login_alert'] as num?) ?? 1).toInt() == 1,
      securityRiskGuard: ((map['security_risk_guard'] as num?) ?? 1).toInt() == 1,
      quietHoursStart: map['quiet_hours_start'] as String?,
      quietHoursEnd: map['quiet_hours_end'] as String?,
    );
  }
}
