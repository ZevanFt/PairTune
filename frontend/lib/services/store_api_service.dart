import '../models/owned_item.dart';
import '../models/product_item.dart';
import 'api_base.dart';

class StoreApiService extends ApiBase {
  StoreApiService({super.client});

  @override
  String get tag => 'Store';

  Future<int> getPoints(String owner) async {
    final data = await get('/store/points?owner=$owner');
    final result = ApiBase.result(data);
    final wallet = result['wallet'] as Map<String, dynamic>;
    return (wallet['points'] as num).toInt();
  }

  Future<void> adjustPoints({required String owner, required int amount, required String reason}) async {
    await postVoid('/store/points/adjust', {'owner': owner, 'amount': amount, 'reason': reason});
  }

  Future<List<ProductItem>> listMarketProducts(String viewer) async {
    final data = await get('/store/products?viewer=$viewer');
    return ApiBase.resultList(data).map(ProductItem.fromMap).toList();
  }

  Future<List<ProductItem>> listMyProducts(String owner) async {
    final data = await get('/store/my-products?owner=$owner');
    return ApiBase.resultList(data).map(ProductItem.fromMap).toList();
  }

  Future<void> createProduct({
    required String publisher,
    required String name,
    required String? description,
    required int pointsCost,
    required int stock,
  }) async {
    await postVoid('/store/products', {
      'publisher': publisher,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'stock': stock,
    });
  }

  Future<void> updateProduct({
    required int id,
    required String owner,
    required String name,
    required String? description,
    required int pointsCost,
    required int stock,
  }) async {
    await put('/store/products/$id', {
      'owner': owner,
      'name': name,
      'description': description,
      'points_cost': pointsCost,
      'stock': stock,
    });
  }

  Future<void> deleteProduct({required int id, required String owner}) async {
    await delete('/store/products/$id?owner=$owner');
  }

  Future<void> exchange({required String buyer, required int productId}) async {
    await postVoid('/store/exchange', {'buyer': buyer, 'product_id': productId});
  }

  Future<List<OwnedItem>> listOwnedItems(String owner) async {
    final data = await get('/store/owned?owner=$owner');
    return ApiBase.resultList(data).map(OwnedItem.fromMap).toList();
  }

  Future<Map<String, dynamic>> exportSnapshot() async {
    final data = await get('/export/snapshot');
    return ApiBase.result(data);
  }
}
