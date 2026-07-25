import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task.dart';
import '../../core/providers/category_provider.dart';

/// Bir görevin tüm alanlarını salt-okunur şekilde gösteren detay ekranı.
/// Şimdilik sadece "inceleme" amaçlı — düzenleme (Task Update aşaması)
/// ayrıca ele alınacak, bkz. README yol haritası.
class TaskDetailScreen extends ConsumerWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  String _repeatLabel(RepeatType type) {
    switch (type) {
      case RepeatType.none:
        return 'Yok';
      case RepeatType.daily:
        return 'Günlük';
      case RepeatType.weekly:
        return 'Haftalık';
      case RepeatType.monthly:
        return 'Aylık';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryById = ref.watch(categoryByIdProvider);
    final categoryName = categoryById[task.categoryId]?.name ?? 'Bilinmeyen kategori';

    return Scaffold(
      appBar: AppBar(title: const Text('Görev Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            task.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            icon: Icons.check_circle_outline,
            label: 'Durum',
            value: task.isCompleted ? 'Tamamlandı' : 'Bekliyor',
          ),
          _DetailRow(
            icon: Icons.event_outlined,
            label: 'Tarih & Saat',
            value: _formatDateTime(task.dueDate),
          ),
          _DetailRow(
            icon: Icons.label_outline,
            label: 'Kategori',
            value: categoryName,
          ),
          _DetailRow(
            icon: Icons.repeat,
            label: 'Tekrar',
            value: _repeatLabel(task.repeat),
          ),
          if (task.description != null && task.description!.trim().isNotEmpty)
            _DetailRow(
              icon: Icons.notes_outlined,
              label: 'Açıklama',
              value: task.description!,
            ),
          _DetailRow(
            icon: Icons.access_time_outlined,
            label: 'Oluşturulma',
            value: _formatDateTime(task.createdAt),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
