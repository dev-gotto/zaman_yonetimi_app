import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import 'repository_provider.dart';
import 'task_provider.dart';

/// deleteCategory çağrısının sonucunu UI'ya taşımak için basit bir sonuç
/// tipi. Exception yerine bunu tercih ettik çünkü "kategori kullanımda"
/// durumu bir hata değil, beklenen bir iş kuralı — UI bunu try/catch yerine
/// düz bir if ile ayırt edebilsin istedik.
class DeleteCategoryResult {
  final bool success;
  final int usageCount;

  const DeleteCategoryResult.success() : success = true, usageCount = 0;
  const DeleteCategoryResult.inUse(this.usageCount) : success = false;
}

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

  /// Kategoriyi siler — ANCAK önce TaskRepository üzerinden bu kategoriyi
  /// kullanan bir görev olup olmadığını kontrol eder. Bu çapraz kontrol
  /// kasıtlı olarak burada (provider katmanında) duruyor: CategoryRepository
  /// sadece kendi verisinden sorumlu, TaskRepository'yi bilmiyor — README'de
  /// planlandığı gibi.
  Future<DeleteCategoryResult> deleteCategory(String id) async {
    final taskRepo = ref.read(taskRepositoryProvider);
    final allTasks = await taskRepo.getAllTasks();
    final usageCount = allTasks.where((t) => t.categoryId == id).length;

    if (usageCount > 0) {
      return DeleteCategoryResult.inUse(usageCount);
    }

    final repo = ref.read(categoryRepositoryProvider);
    await repo.deleteCategory(id);
    state = AsyncValue.data(await repo.getAllCategories());
    return const DeleteCategoryResult.success();
  }
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
