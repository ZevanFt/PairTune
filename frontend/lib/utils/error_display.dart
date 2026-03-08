import '../services/api_error.dart';

String formatErrorMessage(Object error) {
  if (error is ApiHttpError) {
    return '${error.statusCode} ${error.statusText}';
  }
  return '网络错误，请稍后重试';
}
