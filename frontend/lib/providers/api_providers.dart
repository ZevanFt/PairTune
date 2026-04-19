import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/account_api_service.dart';
import '../services/feedback_api_service.dart';
import '../services/health_api_service.dart';
import '../services/store_api_service.dart';
import '../services/task_api_service.dart';

/// Singleton API service providers - accessible from any widget.
final taskApiProvider = Provider((ref) => TaskApiService());
final accountApiProvider = Provider((ref) => AccountApiService());
final storeApiProvider = Provider((ref) => StoreApiService());
final feedbackApiProvider = Provider((ref) => FeedbackApiService());
final healthApiProvider = Provider((ref) => HealthApiService());
