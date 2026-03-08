import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  static const int port = 8110;
  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static bool _logged = false;

  static String get baseUrl {
    final url = _resolveBaseUrl();
    if (!_logged) {
      debugPrint(
        '[ApiConfig] baseUrl=$url platform=${Platform.operatingSystem}',
      );
      _logged = true;
    }
    return url;
  }

  static String _resolveBaseUrl() {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride;
    }
    if (Platform.isAndroid) {
      // 与 our_love 一致：真机默认走 adb reverse，将手机 localhost 映射到电脑端口。
      // 若是 Android 模拟器可通过 --dart-define=API_BASE_URL=http://10.0.2.2:8110 覆盖。
      return 'http://127.0.0.1:$port';
    }
    return 'http://127.0.0.1:$port';
  }
}
