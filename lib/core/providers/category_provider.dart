import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'repository_provider.dart';

class CategoryListNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getAllCategories();
  }

  Future<Category> addCategory(String name) async {
    final repo = ref.read(categoryRepositoryProvider);
    final category = await repo.addCategory(name);
    state = AsyncValue.data(await repo.getAllCategories());
    return category;
  }

  Future<void> renameCategory(String id, String newName) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.renameCategory(id, newName);
    state = AsyncValue.data(await repo.getAllCategories());
  }

  /// Kategoriyi siler. Silmeden önce TaskRepository üzerinden bu kategoriyi
  /// kullanan bir görev olup olmadığını kontrol eder (çapraz sorgu) —
  /// varsa [CategoryInUseException] fırlatır, UI bunu yakalayıp kullanıcıya
  /// gösterir.
  Future<void> deleteCategory(String id) async {
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final taskRepo = ref.read(taskRepositoryProvider);

    final inUse = await taskRepo.isCategoryInUse(id);
    if (inUse) {
      throw CategoryInUseException();
    }

    await categoryRepo.deleteCategory(id);
    state = AsyncValue.data(await categoryRepo.getAllCategories());
  }
}

/// deleteCategory bir görev tarafından kullanılan kategoriyi silmeye
/// çalıştığında fırlatılır. UI bunu yakalayıp kullanıcı dostu bir mesaj
/// gösterir (SnackBar vb.).
class CategoryInUseException implements Exception {
  @override
  String toString() =>
      'Bu kategori en az bir görev tarafından kullanıldığı için silinemez.';
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<Category>>(
      CategoryListNotifier.new,
    );

/// task_list_screen.dart gibi yerlerde bir Task.categoryId'den kategori
/// adını hızlıca göstermek için: categoryId -> Category lookup map'i.
/// categoryListProvider'ı watch ettiği için kategori listesi her
/// değiştiğinde (rename/add/delete) otomatik güncellenir.
final categoryByIdProvider = Provider<Map<String, Category>>((ref) {
  final categoriesAsync = ref.watch(categoryListProvider);
  final categories = categoriesAsync.value ?? const <Category>[];
  return {for (final c in categories) c.id: c};
});
