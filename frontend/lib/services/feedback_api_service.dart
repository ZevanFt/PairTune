import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error.dart';
import 'api_logger.dart';

class FeedbackItem {
  FeedbackItem({
    required this.id,
    required this.owner,
    required this.category,
    required this.title,
    required this.detail,
    this.contact,
    required this.createdAt,
  });

  final int id;
  final String owner;
  final String category;
  final String title;
  final String detail;
  final String? contact;
  final DateTime createdAt;

  static FeedbackItem fromMap(Map<String, dynamic> map) {
    return FeedbackItem(
      id: (map['id'] as num).toInt(),
      owner: map['owner'] as String,
      category: map['category'] as String,
      title: map['title'] as String,
      detail: map['detail'] as String,
      contact: map['contact'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class FeedbackApiService {
  FeedbackApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<List<FeedbackItem>> listFeedback(
    String owner, {
    int limit = 20,
  }) async {
    const path = '/feedback';
    final uri = _uri('$path?owner=$owner&limit=$limit');
    ApiLogger.request('FeedbackApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('FeedbackApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = ((data['result'] as Map<String, dynamic>)['list'] as List)
        .cast<Map<String, dynamic>>()
        .map(FeedbackItem.fromMap)
        .toList();
    return list;
  }

  Future<FeedbackItem> createFeedback({
    required String owner,
    required String category,
    required String title,
    required String detail,
    String? contact,
  }) async {
    const path = '/feedback';
    final uri = _uri(path);
    final payload = {
      'owner': owner,
      'category': category,
      'title': title,
      'detail': detail,
      'contact': contact,
    };
    ApiLogger.request('FeedbackApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('FeedbackApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return FeedbackItem.fromMap(data['result'] as Map<String, dynamic>);
  }
}
