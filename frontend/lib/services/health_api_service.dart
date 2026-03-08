import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_logger.dart';

class BackendHealthStatus {
  const BackendHealthStatus({
    required this.online,
    required this.statusCode,
    required this.statusText,
  });

  final bool online;
  final int statusCode;
  final String statusText;
}

class HealthApiService {
  HealthApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<BackendHealthStatus> checkHealth() async {
    const path = '/health';
    final uri = _uri(path);
    ApiLogger.request('HealthApi', 'GET', uri);
    try {
      final resp = await _client.get(uri).timeout(const Duration(seconds: 3));
      ApiLogger.response('HealthApi', uri, resp);

      if (resp.statusCode == 200) {
        return const BackendHealthStatus(
          online: true,
          statusCode: 200,
          statusText: 'OK',
        );
      }

      String statusText = 'Request Failed';
      try {
        final body = jsonDecode(resp.body);
        if (body is Map<String, dynamic>) {
          final message = body['message'];
          if (message is String && message.trim().isNotEmpty) {
            statusText = message.trim();
          }
        }
      } catch (_) {}

      return BackendHealthStatus(
        online: false,
        statusCode: resp.statusCode,
        statusText: statusText,
      );
    } catch (_) {
      ApiLogger.networkError('HealthApi', 'GET', uri, 'timeout-or-connection');
      return const BackendHealthStatus(
        online: false,
        statusCode: 0,
        statusText: 'Network Error',
      );
    }
  }
}
