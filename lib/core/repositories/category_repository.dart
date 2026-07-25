import '../models/category.dart';

abstract class CategoryRepository {
  Future<void> init();
  Future<List<Category>> getAllCategories();

  /// Yeni bir kategori oluşturur ve id atanmış halini döner.
  Future<Category> addCategory(String name);

  /// Kategoriyi id üzerinden bulur (dropdown/subtitle lookup için).
  Future<Category?> getCategoryById(String id);

  /// Kategori adını değiştirir. FK yapısı sayesinde bu kategoriyi kullanan
  /// tüm görevlere otomatik yansır (Task, categoryId üzerinden referans
  /// verdiği için görev tarafında ayrıca bir güncelleme gerekmez).
  Future<void> renameCategory(String id, String newName);

  /// Kategoriyi siler. Kullanım kontrolü (bir görev tarafından kullanılıp
  /// kullanılmadığı) bu katmanın sorumluluğunda değildir — çağıran taraf
  /// (provider/UI) TaskRepository üzerinden kontrol edip karar verecek.
  Future<void> deleteCategory(String id);
}
