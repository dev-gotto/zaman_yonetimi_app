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
    // Not: task.save() yerine _box.put() kullanıyoruz. Düzenleme akışı
    // (task_list_screen.dart) mevcut görevi güncellerken addTask ile aynı
    // pattern'i izleyip box'a bağlı OLMAYAN yeni bir Task nesnesi kuruyor
    // (aynı id ile). task.save() sadece box'tan gelen, box'a zaten bağlı
    // nesnelerde çalışır — yeni oluşturulmuş bir nesnede HiveError fırlatır.
    // _box.put(key, value) ise key eşleşirse var olan kaydı sorunsuz
    // overwrite eder, ekstra bir "box'a bağlama" adımına gerek kalmaz.
    await _box.put(task.id, task);
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

  @override
  Future<bool> isCategoryInUse(String categoryId) async {
    return _box.values.any((task) => task.categoryId == categoryId);
  }
}
