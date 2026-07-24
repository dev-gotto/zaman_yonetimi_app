import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/task_repository.dart';
import '../repositories/hive_task_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/hive_category_repository.dart';
import '../services/notification_service.dart';

// İleride Hive yerine başka bir DB kullanmak istersen
// SADECE bu satırı değiştirmen yeterli olacak.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return HiveTaskRepository();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return HiveCategoryRepository();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
