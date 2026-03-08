import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_error.dart';
import 'api_logger.dart';

class ProductItem {
  ProductItem({
    required this.id,
    required this.publisher,
    required this.name,
    this.description,
    required this.pointsCost,
    required this.stock,
  });

  final int id;
  final String publisher;
  final String name;
  final String? description;
  final int pointsCost;
  final int stock;

  static ProductItem fromMap(Map<String, dynamic> map) {
    return ProductItem(
      id: (map['id'] as num).toInt(),
      publisher: map['publisher'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      pointsCost: (map['points_cost'] as num).toInt(),
      stock: (map['stock'] as num).toInt(),
    );
  }
}

class OwnedItem {
  OwnedItem({
    required this.id,
    required this.productName,
    required this.pointsSpent,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final int pointsSpent;
  final DateTime createdAt;

  static OwnedItem fromMap(Map<String, dynamic> map) {
    return OwnedItem(
      id: (map['id'] as num).toInt(),
      productName: map['product_name'] as String,
      pointsSpent: (map['points_spent'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class StoreApiService {
  StoreApiService({http.Client? client}) : _client = client ?? http.Client();

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

  Future<int> getPoints(String owner) async {
    const path = '/store/points';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('StoreApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    final wallet = result['wallet'] as Map<String, dynamic>;
    return (wallet['points'] as num).toInt();
  }

  Future<void> adjustPoints({
    required String owner,
    required int amount,
    required String reason,
  }) async {
    const path = '/store/points/adjust';
    final uri = _uri(path);
    final payload = {'owner': owner, 'amount': amount, 'reason': reason};
    ApiLogger.request('StoreApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<List<ProductItem>> listMarketProducts(String viewer) async {
    const path = '/store/products';
    final uri = _uri('$path?viewer=$viewer');
    ApiLogger.request('StoreApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = ((data['result'] as Map<String, dynamic>)['list'] as List)
        .cast<Map<String, dynamic>>()
        .map(ProductItem.fromMap)
        .toList();
    return list;
  }

  Future<List<ProductItem>> listMyProducts(String owner) async {
    const path = '/store/my-products';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('StoreApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = ((data['result'] as Map<String, dynamic>)['list'] as List)
        .cast<Map<String, dynamic>>()
        .map(ProductItem.fromMap)
        .toList();
    return list;
  }

  Future<void> createProduct({
    required String publisher,
    required String name,
    required String? description,
    required int pointsCost,
    required int stock,
  }) async {
    const path = '/store/products';
    final uri = _uri(path);
    final payload = {
      'publisher': publisher,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'stock': stock,
    };
    ApiLogger.request('StoreApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<void> updateProduct({
    required int id,
    required String owner,
    required String name,
    required String? description,
    required int pointsCost,
    required int stock,
  }) async {
    final path = '/store/products/$id';
    final uri = _uri(path);
    final payload = {
      'owner': owner,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'stock': stock,
    };
    ApiLogger.request('StoreApi', 'PUT', uri, body: jsonEncode(payload));
    final resp = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<void> deleteProduct({required int id, required String owner}) async {
    final path = '/store/products/$id';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('StoreApi', 'DELETE', uri);
    final resp = await _client.delete(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<void> exchange({required String buyer, required int productId}) async {
    const path = '/store/exchange';
    final uri = _uri(path);
    final payload = {'buyer': buyer, 'product_id': productId};
    ApiLogger.request('StoreApi', 'POST', uri, body: jsonEncode(payload));
    final resp = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
  }

  Future<List<OwnedItem>> listOwnedItems(String owner) async {
    const path = '/store/owned';
    final uri = _uri('$path?owner=$owner');
    ApiLogger.request('StoreApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final list = ((data['result'] as Map<String, dynamic>)['list'] as List)
        .cast<Map<String, dynamic>>()
        .map(OwnedItem.fromMap)
        .toList();
    return list;
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    const path = '/export/snapshot';
    final uri = _uri(path);
    ApiLogger.request('StoreApi', 'GET', uri);
    final resp = await _client.get(uri);
    ApiLogger.response('StoreApi', uri, resp);
    _ensureOk(resp, path);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['result'] as Map<String, dynamic>;
  }
}
