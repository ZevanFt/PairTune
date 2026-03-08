import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiLogger {
  static const int _maxLogs = 200;
  static final List<String> _logs = <String>[];

  static List<String> recent({int limit = 80}) {
    if (_logs.isEmpty) return const [];
    final safe = limit < 1 ? 1 : limit;
    final start = _logs.length > safe ? _logs.length - safe : 0;
    return List<String>.unmodifiable(_logs.sublist(start));
  }

  static void clear() {
    _logs.clear();
  }

  static void request(String tag, String method, Uri uri, {Object? body}) {
    final bodyText = body == null ? '' : ' body=${_truncate(body.toString())}';
    _append('[$tag] -> $method ${uri.toString()}$bodyText');
  }

  static void response(String tag, Uri uri, http.Response resp) {
    _append(
      '[$tag] <- ${resp.statusCode} ${uri.toString()} msg=${_messageFrom(resp)}',
    );
  }

  static void networkError(String tag, String method, Uri uri, Object error) {
    _append(
      '[$tag] xx $method ${uri.toString()} error=${error.runtimeType} ${_truncate(error.toString())}',
    );
  }

  static String messageFromResponse(http.Response resp) => _messageFrom(resp);

  static String _messageFrom(http.Response resp) {
    try {
      final body = jsonDecode(resp.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}
    return 'Request Failed';
  }

  static String _truncate(String input, {int max = 240}) {
    if (input.length <= max) return input;
    return '${input.substring(0, max)}...';
  }

  static void _append(String line) {
    final stamped = '${DateTime.now().toIso8601String()} $line';
    _logs.add(stamped);
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }
    debugPrint(stamped);
  }
}
