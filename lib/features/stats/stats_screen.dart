import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/stats_provider.dart';
import '../../core/providers/category_provider.dart';

/// Tamamlanan/bekleyen görev sayıları ve kategoriye göre dağılım.
/// Kasıtlı olarak sade tutuldu (proje sonunda UI cilalaması ayrıca
/// yapılacak, bkz. README "Çalışma Tarzı Tercihleri").
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(taskStatsProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    final categoryEntries = stats.countByCategoryId.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(label: 'Toplam', value: stats.total),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: 'Tamamlanan', value: stats.completed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: 'Bekleyen', value: stats.pending),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Kategoriye göre dağılım',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (categoryEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Henüz görev yok.'),
            )
          else
            ...categoryEntries.map((entry) {
              final name =
                  categoryById[entry.key]?.name ?? 'Bilinmeyen kategori';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
