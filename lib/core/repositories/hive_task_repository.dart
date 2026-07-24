import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import 'task_repository.dart';

class HiveTaskRepository implements TaskRepository {
  static const String boxName = 'tasks';
  late Box<Task> _box;

  @override
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    _box = await Hive.openBox<Task>(boxName);
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final tasks = _box.values.toList();
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  @override
  Future<List<Task>> getTasksByDate(DateTime date) async {
    final tasks = _box.values.where((task) {
      return task.dueDate.year == date.year &&
          task.dueDate.month == date.month &&
          task.dueDate.day == date.day;
    }).toList();
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  @override
  Future<void> addTask(Task task) async {
    await _box.put(task.id, task);
  }

  @override
  Future<void> updateTask(Task task) async {
    await task.save();
  }

  @override
  Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> toggleComplete(String id) async {
    final task = _box.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await task.save();
    }
  }
}
