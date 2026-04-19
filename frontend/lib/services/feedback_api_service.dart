import '../models/feedback_item.dart';
import 'api_base.dart';

class FeedbackApiService extends ApiBase {
  FeedbackApiService({super.client});

  @override
  String get tag => 'Feedback';

  Future<List<FeedbackItem>> listFeedback(String owner, {int limit = 20}) async {
    final data = await get('/feedback?owner=$owner&limit=$limit');
    return ApiBase.resultList(data).map(FeedbackItem.fromMap).toList();
  }

  Future<FeedbackItem> createFeedback({
    required String owner,
    required String category,
    required String title,
    required String detail,
    String? contact,
  }) async {
    final data = await post('/feedback', {
      'owner': owner,
      'category': category,
      'title': title,
      'detail': detail,
      'contact': contact,
    });
    return FeedbackItem.fromMap(ApiBase.result(data));
  }
}
