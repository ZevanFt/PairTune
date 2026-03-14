const APP_CONFIG = {
  feedback: {
    titleMax: 30,
    detailMax: 200,
    contactMax: 40,
    categoryMax: 20,
    listLimitMax: 100,
  },
  systemSettings: {
    defaults: {
      siteName: '合拍',
      supportEmail: '',
      supportPhone: '',
      announcement: '',
      maintenanceMode: 0,
      smsProvider: 'mock',
      emailProvider: 'mock',
    },
    limits: {
      siteNameMax: 20,
      supportEmailMax: 80,
      supportPhoneMax: 30,
      announcementMax: 200,
    },
    providers: {
      sms: ['mock', 'tencent'],
      email: ['mock', 'smtp'],
    },
  },
};

module.exports = { APP_CONFIG };
