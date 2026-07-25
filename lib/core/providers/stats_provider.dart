import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';

class TaskStats {
  final int total;
  final int completed;
  final int pending;

  /// categoryId -> o kategoriye ait görev sayısı.
  final Map<String, int> countByCategoryId;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.countByCategoryId,
  });

  const TaskStats.empty()
    : total = 0,
      completed = 0,
      pending = 0,
      countByCategoryId = const {};
}

/// Performans notu: tüm sayaçlar (toplam/tamamlanan/bekleyen/kategori
/// dağılımı) tasks listesi üzerinde TEK geçişte (single pass, O(N))
/// hesaplanıyor. Bunun yerine her sayaç için ayrı ayrı .where().length
/// çağırmak (4 ayrı O(N) tarama) görev sayısı büyüdükçe gereksiz maliyet
/// biriktirirdi.
///
/// Bu düz bir Provider (AsyncNotifier değil) — Riverpod, izlediği
/// taskListProvider değişmediği sürece sonucu otomatik önbellekte tutar,
/// ekran her rebuild olduğunda yeniden hesaplamaz.
final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final tasks = tasksAsync.value;
  if (tasks == null || tasks.isEmpty) {
    return const TaskStats.empty();
  }

  var completed = 0;
  final countByCategoryId = <String, int>{};

  for (final task in tasks) {
    if (task.isCompleted) completed++;
    countByCategoryId.update(
      task.categoryId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }

  return TaskStats(
    total: tasks.length,
    completed: completed,
    pending: tasks.length - completed,
    countByCategoryId: countByCategoryId,
  );
});
