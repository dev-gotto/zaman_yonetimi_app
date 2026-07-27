import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';
import 'category_name_dialog.dart';

/// Kategori tam CRUD ekranı — rename ve delete burada.
/// Kasıtlı olarak sade tutuldu (proje sonunda UI cilalaması ayrıca
/// yapılacak, bkz. README "Çalışma Tarzı Tercihleri").
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorileri Yönet')),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Henüz kategori yok.'));
          }
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                title: Text(category.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Yeniden adlandır',
                      onPressed: () => _showRenameDialog(context, category),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Sil',
                      onPressed: () => _handleDelete(context, ref, category),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Not (düzeltme, 28 Temmuz 2026): Bu iki diyalog önceden kendi
  // TextEditingController'larını doğrudan burada tutuyor, dispose()'unu
  // showDialog()'un Future'ına (.whenComplete) bağlıyordu. Gerçek cihazda
  // bu, tam olarak task_list_screen.dart'ta görülen aynı çökmeye yol açtı
  // ("TextEditingController was used after being disposed" — rename
  // diyaloğunda tetiklendi). Kök neden liste sıralamasıyla değil, dış
  // Future zamanlamasının kendisiyle ilgiliydi. Artık ikisi de ortak,
  // widget-yaşam-döngüsüne bağlı CategoryNameDialog'u kullanıyor — bkz.
  // category_name_dialog.dart'taki açıklama.
  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoryNameDialog(
        title: 'Yeni Kategori',
        confirmLabel: 'Ekle',
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (context) => CategoryNameDialog(
        title: 'Yeniden Adlandır',
        confirmLabel: 'Kaydet',
        existingCategory: category,
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text('"${category.name}" kategorisini silmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref
        .read(categoryListProvider.notifier)
        .deleteCategory(category.id);

    if (!context.mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bu kategori ${result.usageCount} görev tarafından kullanılıyor, '
            'silinemez.',
          ),
        ),
      );
    }
  }
}
