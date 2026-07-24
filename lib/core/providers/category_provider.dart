import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_provider.dart';

class CategoryListNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    final repo = ref.read(categoryRepositoryProvider);
    return repo.getAllCategories();
  }

  Future<void> addCategory(String name) async {
    final repo = ref.read(categoryRepositoryProvider);
    await repo.addCategory(name);
    state = AsyncValue.data(await repo.getAllCategories());
  }
}

final categoryListProvider =
    AsyncNotifierProvider<CategoryListNotifier, List<String>>(
  CategoryListNotifier.new,
);