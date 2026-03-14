class AppStrings {
  static const appName = '合拍 PairTune';
  static const appTag = 'PAIRTUNE';
  static const appSubtitle = '协作型任务与积分应用';
  static const appTeamName = 'PairTune Team';
  static const appVersion = 'v1.0.0';
  static const profileTitle = '个人中心';
  static const profileSectionInfoTitle = '资料与关系';
  static const profileSectionInfoSubtitle = '编辑资料并维护协作身份';
  static const profileSectionAccountTitle = '账号与通知';
  static const profileSectionAccountSubtitle = '管理账号安全并调整消息提醒';
  static const profileSectionSupportTitle = '支持与隐私';
  static const profileSectionSupportSubtitle = '反馈问题并管理隐私数据';
  static const profileEdit = '编辑资料';
  static const profileEditSubtitle = '完善头像、昵称与简介';
  static const profileRelationship = '关系管理';
  static const profileRelationshipSubtitle = '协作标签与偏好';
  static const profileDuoMode = '双人协作模式';
  static const profileDuoModeOn = '已开启：可切换我/搭档视角';
  static const profileDuoModeOff = '已关闭：当前为单人模式';
  static const profileAccountSecurity = '账号安全';
  static const profileAccountSecuritySubtitle = '本地安全设置与检查';
  static const profileNotification = '通知开关';
  static const profileNotificationSubtitle = '任务提醒与商城提醒';
  static const profileHelp = '帮助与反馈';
  static const profileHelpSubtitle = '问题反馈与产品建议';
  static const profilePrivacy = '隐私与数据';
  static const profilePrivacySubtitle = '导出数据、清理缓存';
  static const profileAbout = '关于';
  static const profileAboutSubtitle = '作者与开源依赖说明';
  static const profileLogout = '退出登录';
  static const profileLogoutSubtitle = '退出当前账号并回到登录页';
  static const profileLogoutTitle = '退出登录';
  static const profileLogoutHint = '退出后需要重新登录才能继续使用';
  static const profileLogoutCancel = '取消';
  static const profileLogoutConfirm = '确认退出';
  static const profileDebugHint =
      '提示：连续点击头像卡片 5 次，再点版本号 3 次可开启调试入口（仅开发环境可见）';
  static const profileDebugTitle = '调试页面';
  static const profileDebugSubtitle = '查看 API 日志并运行网络诊断';
  static const profileDebugUnlocked = '调试入口已开启';
  static const profileGuestTitle = '登录后解锁完整功能';
  static const profileGuestSubtitle = '当前为体验模式，仅保留查看与基础操作。';
  static const profileGuestAction = '去登录';
  static const profileVersion = '合拍 PairTune · v1.0.0';
  static const profileDefaultName = '合拍用户';
  static const profileLoading = '加载中...';
  static const profileOwnerPlaceholder = '...';
  static const profileModeLabel = '当前模式';
  static const profileModeDuo = '双人';
  static const profileModeSolo = '单人';
  static const profileOwnerLabel = '当前身份';
  static const profileOwnerMe = '我';
  static const profileOwnerPartner = '搭档';

  static const profileSaving = '保存中...';
  static const profileModeSyncFail = '模式同步失败';
  static const profileSettingFail = '设置失败';
  static const profileErrorLoading = '加载失败';

  static const editProfileTitle = '编辑资料';
  static const editProfileSave = '保存资料';
  static const editProfileSaving = '保存中...';
  static const editProfileSectionBasic = '基础信息';
  static const editProfileSectionBasicHint = '昵称用于任务、通知与协作展示';
  static const editProfileDisplayName = '昵称';
  static const editProfileBio = '个人简介';
  static const editProfileBioHint = '一句话介绍自己';
  static const editProfileSectionAvatar = '头像风格';
  static const editProfileSectionAvatarHint = '选择一个代表你的形象';
  static const editProfileSectionRelation = '关系标签';
  static const editProfileSectionRelationHint = '用于展示你与搭档的关系';
  static const editProfileCustomLabel = '自定义标签';
  static const editProfileCustomLabelHint = '例如：同事、学习搭子';
  static const editProfileSaved = '资料已更新';
  static const editProfileAvatarSunny = '日光';
  static const editProfileAvatarMoon = '月光';
  static const editProfileAvatarLeaf = '叶子';
  static const editProfileAvatarSpark = '闪光';
  static const editProfileAvatarWave = '海浪';
  static const editProfileAvatarShield = '护盾';
  static const List<String> relationshipPresets = [
    '搭档',
    '恋人',
    '家人',
    '同事',
    '室友',
    '闺蜜',
    '好友',
  ];
  static const editProfileNameMin = '昵称至少 {min} 个字';
  static const editProfileNameMax = '昵称最多 {max} 个字';
  static const editProfileBioMax = '简介最多 {max} 个字';
  static const editProfileRelationRequired = '请输入关系标签';
  static const editProfileRelationMax = '标签最多 {max} 个字';

  static const relationshipTitle = '关系管理';
  static const relationshipSectionLabel = '关系标签';
  static const relationshipSectionLabelHint = '用于对外展示你和搭档的关系';
  static const relationshipSectionPrefs = '协作偏好';
  static const relationshipPrefCheckin = '每周复盘提醒';
  static const relationshipPrefCheckinHint = '每周同步目标与进度';
  static const relationshipPrefReminder = '任务共创提醒';
  static const relationshipPrefReminderHint = '创建共享任务时提示搭档';
  static const relationshipPrefCoop = '积分协作提示';
  static const relationshipPrefCoopHint = '兑换奖励时提醒对方';
  static const relationshipSave = '保存关系设置';
  static const relationshipSaved = '关系设置已更新';
  static const relationshipSaving = '保存中...';
  static const relationshipLabelRequired = '请输入关系标签';
  static const relationshipLabelMax = '标签最多 {max} 个字';

  static const accountSecurityTitle = '账号安全';
  static const accountSecuritySectionAlerts = '安全提醒';
  static const accountSecurityLoginAlert = '登录提醒';
  static const accountSecurityLoginAlertHint = '本地记录登录行为并提醒';
  static const accountSecurityRiskGuard = '风险提示';
  static const accountSecurityRiskGuardHint = '检测到异常操作时提醒';
  static const accountSecuritySectionCheck = '密码强度检查';
  static const accountSecurityPassword = '输入密码';
  static const accountSecurityPasswordHint = '本地检测，不会上传';
  static const accountSecurityStrengthLabel = '强度';
  static const accountSecurityWeak = '弱';
  static const accountSecurityMedium = '中';
  static const accountSecurityStrong = '强';
  static const accountSecurityTipShort = '长度至少 8 位';
  static const accountSecurityTipMix = '包含大小写与数字';
  static const accountSecurityTipSymbol = '加入特殊字符更安全';

  static const introFeatureTitle1 = '要事第一';
  static const introFeatureSubtitle1 = '四象限聚焦重要任务';
  static const introFeatureTitle2 = '积分激励';
  static const introFeatureSubtitle2 = '完成任务获得奖励';
  static const introFeatureTitle3 = '关系协作';
  static const introFeatureSubtitle3 = '双人模式更有陪伴感';
  static const introLogin = '去登录';
  static const introGuest = '先体验应用（游客模式）';

  static const authLoginTitle = '登录';
  static const authLoginSubtitle = '使用账号与密码登录';
  static const authAccountPanelTitle = '账号登录';
  static const authAccountPanelSubtitle = '输入账号和密码继续';
  static const authAccountLabel = '账号';
  static const authAccountHint = '4-20位字母/数字/下划线';
  static const authPasswordLabel = '密码';
  static const authPasswordHint = '至少6位';
  static const authLoginButton = '账号登录';
  static const authNoAccount = '没有账号？';
  static const authGoRegister = '去注册';
  static const authGuest = '先体验应用（游客模式）';
  static const authFailPrefix = '认证失败：';

  static const registerTitle = '注册账号';
  static const registerPanelTitle = '注册';
  static const registerPanelSubtitle = '需要邀请码才可创建账号';
  static const registerDisplayNameLabel = '昵称';
  static const registerDisplayNameHint = '输入昵称（可选）';
  static const registerAccountLabel = '账号';
  static const registerPasswordLabel = '密码';
  static const registerInviteLabel = '邀请码';
  static const registerInviteHint = '请输入管理员提供的邀请码';
  static const registerSubmit = '创建账号';
  static const registerDefaultName = '新用户';
  static const registerSuccess = '注册成功，请登录';
  static const registerFailPrefix = '注册失败：';

  static const modeTag = 'PAIR MODE';
  static const modeTitle = '合拍 PairTune';
  static const modeSubtitle = '一个人也能用，两个人更好用。';
  static const modeSoloTitle = '先单人开始';
  static const modeSoloSubtitle = '独立管理任务和积分，后续可随时升级双人协作';
  static const modeDuoTitle = '邀请搭档一起';
  static const modeDuoSubtitle = '开启双人视角、协作提醒与奖励互动';

  static const aboutTitle = '关于';
  static const aboutHeaderTitle = '合拍 PairTune';
  static const aboutHeaderSubtitle = '协作型任务与积分应用';
  static const aboutSectionAuthor = '作者信息';
  static const aboutSectionOpenSource = '开源说明';
  static const aboutSectionDeps = '依赖列表';
  static const aboutAuthorLabel = '作者';
  static const aboutVersionLabel = '版本';
  static const aboutFrameworkLabel = '框架';
  static const aboutUiLabel = 'UI 组件';
  static const aboutDataLabel = '数据存储';
  static const aboutNetLabel = '网络与格式';
  static const aboutLicenseLabel = '许可证提示';
  static const aboutOpenSourceDesc = '本应用仅使用开源框架与依赖库。商业使用请遵循各依赖库的许可证要求，具体授权以各项目 LICENSE 为准。';
  static const aboutFrameworkValue = 'Flutter / Dart';
  static const aboutUiValue = 'Material / Cupertino Icons';
  static const aboutDataValue = 'sqflite / path';
  static const aboutNetValue = 'http / intl';
  static const aboutLicenseValue = '请以各依赖库 LICENSE 为准';
  static const aboutDepFlutter = 'flutter';
  static const aboutDepCupertino = 'cupertino_icons';
  static const aboutDepSqflite = 'sqflite';
  static const aboutDepPath = 'path';
  static const aboutDepIntl = 'intl';
  static const aboutDepHttp = 'http';
  static const aboutDepSdk = 'SDK';
  static const aboutDepCupertinoVersion = '^1.0.8';
  static const aboutDepSqfliteVersion = '^2.4.2';
  static const aboutDepPathVersion = '^1.9.1';
  static const aboutDepIntlVersion = '^0.20.2';
  static const aboutDepHttpVersion = '^1.2.2';

  static const helpTitle = '帮助与反馈';
  static const helpSectionFaq = '常见问题';
  static const helpSectionFaqHint = '快速了解核心使用方式';
  static const helpSectionFeedback = '反馈表单';
  static const helpSectionFeedbackHint = '描述问题或建议，我们会持续优化';
  static const helpFeedbackCategory = '问题类型';
  static const helpFeedbackTitle = '标题';
  static const helpFeedbackDetail = '详细描述';
  static const helpFeedbackContact = '联系方式（可选）';
  static const helpFeedbackSubmit = '提交反馈';
  static const helpFeedbackCopy = '复制内容';
  static const helpFeedbackSubmitting = '提交中...';
  static const helpFeedbackCopied = '反馈内容已复制';
  static const helpFeedbackSaved = '反馈已保存到本地';
  static const helpRecentFeedback = '最近反馈';
  static const helpFeedbackTitleRequired = '请输入标题';
  static const helpFeedbackTitleMax = '标题最多 {max} 个字';
  static const helpFeedbackDetailRequired = '请描述具体问题';
  static const helpFeedbackDetailMax = '描述最多 {max} 个字';
  static const helpFeedbackContactMax = '联系方式最多 {max} 个字';
  static const helpFeedbackCopyTooltip = '复制';
  static const List<String> feedbackCategories = [
    '体验问题',
    '功能建议',
    '任务体验',
    '积分商城',
    '其他',
  ];
  static const helpFaqQ1 = '如何开始协作？';
  static const helpFaqA1 = '在个人中心开启双人模式，并邀请搭档一起制定任务。';
  static const helpFaqQ2 = '积分如何获得？';
  static const helpFaqA2 = '完成任务会自动累计积分，可在商城兑换奖励。';
  static const helpFaqQ3 = '体验模式会保存吗？';
  static const helpFaqA3 = '体验模式的数据只保存在本机，不会同步到云端。';

  static const privacyTitle = '隐私与数据';
  static const privacySectionSnapshot = '数据快照';
  static const privacySectionSnapshotHint = '查看当前账户数据概览';
  static const privacySnapshotAction = '拉取快照';
  static const privacySnapshotReady = '快照已更新';
  static const privacySnapshotLoading = '拉取中...';
  static const privacySectionLocal = '本机数据';
  static const privacyClearTasks = '清理本机任务缓存';
  static const privacyClearTasksHint = '仅清理设备上的离线任务';
  static const privacyClearPrefs = '重置账号偏好设置';
  static const privacyClearPrefsHint = '重置关系与安全偏好';
  static const privacyConfirmTitle = '确认操作';
  static const privacyConfirmCancel = '取消';
  static const privacyConfirmOk = '确认清理';
  static const privacyClearedTasks = '本机任务缓存已清理';
  static const privacyClearedPrefs = '账号偏好设置已重置';
  static const privacyConfirmDetail = '即将执行：{title}';

  static String profileCompletionRate(int rate) => '完成率 $rate%';
  static String profileOwnerId(String owner) => 'PairTune ID: $owner';
  static String privacySnapshotSummary(int tasks, int products, int ledger) =>
      '任务 $tasks · 商品 $products · 流水 $ledger';
  static String helpFeedbackLimit(int current, int max) => '$current/$max';
  static String profileModeSyncFailDetail(String detail) =>
      '$profileModeSyncFail: $detail';
  static String profileSettingFailDetail(String detail) =>
      '$profileSettingFail: $detail';
  static String profileErrorLoadingDetail(String detail) =>
      '$profileErrorLoading：$detail';
  static String editProfileNameMinDetail(int min) =>
      editProfileNameMin.replaceAll('{min}', '$min');
  static String editProfileNameMaxDetail(int max) =>
      editProfileNameMax.replaceAll('{max}', '$max');
  static String editProfileBioMaxDetail(int max) =>
      editProfileBioMax.replaceAll('{max}', '$max');
  static String editProfileRelationMaxDetail(int max) =>
      editProfileRelationMax.replaceAll('{max}', '$max');
  static String relationshipLabelMaxDetail(int max) =>
      relationshipLabelMax.replaceAll('{max}', '$max');
  static String helpFeedbackTitleMaxDetail(int max) =>
      helpFeedbackTitleMax.replaceAll('{max}', '$max');
  static String helpFeedbackDetailMaxDetail(int max) =>
      helpFeedbackDetailMax.replaceAll('{max}', '$max');
  static String helpFeedbackContactMaxDetail(int max) =>
      helpFeedbackContactMax.replaceAll('{max}', '$max');
  static String privacyConfirmDetailText(String title) =>
      privacyConfirmDetail.replaceAll('{title}', title);
}
