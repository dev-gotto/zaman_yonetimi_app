import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import 'repository_provider.dart';

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final repo = ref.read(taskRepositoryProvider);
    return repo.getAllTasks();
  }

  Future<void> addTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.addTask(task);

    // ignore: avoid_print
    print('### [TaskProvider] repo.addTask tamamlandi ###');

    final notificationService = ref.read(notificationServiceProvider);

    // ignore: avoid_print
    print(
      '### [TaskProvider] notificationService alindi: $notificationService ###',
    );

    await notificationService.scheduleTaskNotification(
      id: task.id.hashCode,
      title: task.title,
      body: task.description ?? 'Görev zamanı geldi',
      scheduledDate: task.dueDate,
    );

    // ignore: avoid_print
    print('### [TaskProvider] scheduleTaskNotification await TAMAMLANDI ###');

    state = AsyncValue.data(await repo.getAllTasks());
  }

  Future<void> updateTask(Task task) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.updateTask(task);

    // Performans notu: native bildirim çağrıları (özellikle zonedSchedule)
    // diğer repo/provider işlemlerine göre daha maliyetli — bu yüzden
    // gereksiz yere iki kez çağırmıyoruz. Eskisini her durumda iptal ediyoruz
    // (ucuz işlem), ama yeniden planlamayı SADECE görev tamamlanmamışsa
    // yapıyoruz — tamamlanmış bir görev için zaten bildirime gerek yok,
    // scheduleTaskNotification'ı boş yere çağırıp geçmiş tarih kontrolüne
    // takılmasına gerek bırakmıyoruz.
    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.cancelNotification(task.id.hashCode);
    if (!task.isCompleted) {
      await notificationService.scheduleTaskNotification(
        id: task.id.hashCode,
        title: task.title,
        body: task.description ?? 'Görev zamanı geldi',
        scheduledDate: task.dueDate,
      );
    }

    state = AsyncValue.data(await repo.getAllTasks());
  }

  Future<void> deleteTask(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.deleteTask(id);

    final notificationService = ref.read(notificationServiceProvider);
    await notificationService.cancelNotification(id.hashCode);

    state = AsyncValue.data(await repo.getAllTasks());
  }

  Future<void> toggleComplete(String id) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.toggleComplete(id);

    final tasks = await repo.getAllTasks();
    final task = tasks.where((t) => t.id == id).firstOrNull;
    if (task != null && task.isCompleted) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelNotification(id.hashCode);
    }

    state = AsyncValue.data(tasks);
  }
}

final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  () {
    return TaskListNotifier();
  },
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

final tasksForSelectedDateProvider = Provider<List<Task>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final asyncTasks = ref.watch(taskListProvider);

  final allTasks = asyncTasks.value ?? [];

  return allTasks.where((task) {
    return task.dueDate.year == selectedDate.year &&
        task.dueDate.month == selectedDate.month &&
        task.dueDate.day == selectedDate.day;
  }).toList();
});
