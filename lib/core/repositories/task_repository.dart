import '../models/task.dart';

abstract class TaskRepository {
  Future<void> init();
  Future<List<Task>> getAllTasks();
  Future<List<Task>> getTasksByDate(DateTime date);
  Future<void> addTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> toggleComplete(String id);
}