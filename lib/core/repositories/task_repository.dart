import '../models/task.dart';

abstract class TaskRepository {
  Future<void> init();
  Future<List<Task>> getAllTasks();
  Future<List<Task>> getTasksByDate(DateTime date);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleComplete(String id);

  /// Bir kategori en az bir görev tarafından kullanılıyor mu?
  /// CategoryListNotifier.deleteCategory bunu, silme öncesi kullanım
  /// kontrolü (çapraz sorgu) için çağırır.
  Future<bool> isCategoryInUse(String categoryId);
}