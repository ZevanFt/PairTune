import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error.dart';
import 'api_logger.dart';

/// Unified API base class providing common HTTP methods, logging, and error handling.
/// All API services should extend this class instead of reimplementing boilerplate.
abstract class ApiBase {
  ApiBase({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Tag name for logging (e.g. 'Auth', 'Task', 'Store')
  String get tag;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  // ─── GET ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String path) async {
    final uri = _uri(path);
    ApiLogger.request(tag, 'GET', uri);
    final resp = await _client.get(uri, headers: _jsonHeaders);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ─── POST ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    final encoded = jsonEncode(body);
    ApiLogger.request(tag, 'POST', uri, body: encoded);
    final resp = await _client.post(uri, headers: _jsonHeaders, body: encoded);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// POST that doesn't return a parsed body (e.g. logout, mark-read)
  Future<void> postVoid(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    final encoded = jsonEncode(body);
    ApiLogger.request(tag, 'POST', uri, body: encoded);
    final resp = await _client.post(uri, headers: _jsonHeaders, body: encoded);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
  }

  // ─── PUT ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    final encoded = jsonEncode(body);
    ApiLogger.request(tag, 'PUT', uri, body: encoded);
    final resp = await _client.put(uri, headers: _jsonHeaders, body: encoded);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ─── PATCH ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final uri = _uri(path);
    final encoded = jsonEncode(body);
    ApiLogger.request(tag, 'PATCH', uri, body: encoded);
    final resp = await _client.patch(uri, headers: _jsonHeaders, body: encoded);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  // ─── DELETE ─────────────────────────────────────────────────────────────

  Future<void> delete(String path) async {
    final uri = _uri(path);
    ApiLogger.request(tag, 'DELETE', uri);
    final resp = await _client.delete(uri, headers: _jsonHeaders);
    ApiLogger.response(tag, uri, resp);
    _ensureOk(resp, path);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  void _ensureOk(http.Response resp, String path) {
    if (resp.statusCode != 200) {
      throw ApiHttpError(
        statusCode: resp.statusCode,
        statusText: ApiLogger.messageFromResponse(resp),
        endpoint: path,
      );
    }
  }

  /// Extract the 'result' field from a standard API response.
  static Map<String, dynamic> result(Map<String, dynamic> response) {
    return response['result'] as Map<String, dynamic>;
  }

  /// Extract a list from 'result.list' in a standard API response.
  static List<Map<String, dynamic>> resultList(Map<String, dynamic> response) {
    final r = response['result'] as Map<String, dynamic>;
    return (r['list'] as List).cast<Map<String, dynamic>>();
  }
}
