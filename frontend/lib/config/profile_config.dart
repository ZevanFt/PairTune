class ProfileConfig {
  static const int displayNameMin = 2;
  static const int displayNameMax = 16;
  static const int bioMax = 80;
  static const int relationshipLabelMax = 8;
  static const int feedbackTitleMax = 30;
  static const int feedbackBodyMax = 200;
  static const int feedbackContactMax = 40;

  static const String prefRelationshipCheckin = 'pf_relation_checkin';
  static const String prefRelationshipReminder = 'pf_relation_reminder';
  static const String prefRelationshipCoopHint = 'pf_relation_coop_hint';
  static const String prefSecurityLoginAlert = 'pf_security_login_alert';
  static const String prefSecurityRiskGuard = 'pf_security_risk_guard';
  static const String prefFeedbackItems = 'pf_feedback_items';
}
