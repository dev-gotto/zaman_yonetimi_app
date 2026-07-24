abstract class CategoryRepository {
  Future<void> init();
  Future<List<String>> getAllCategories();
  Future<void> addCategory(String name);
}