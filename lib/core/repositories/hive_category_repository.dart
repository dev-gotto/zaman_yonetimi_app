import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'category_repository.dart';

class HiveCategoryRepository implements CategoryRepository {
  // Kategori-FK migration ile birlikte kategoriler artık bu yeni box'ta
  // (Box<Category>) tutuluyor. Eski 'categories' box'ı (Box<String>) hâlâ
  // diskte duruyor ama artık bu repository tarafından kullanılmıyor —
  // CategoryFkMigration tek seferlik olarak oradan veri taşıyor.
  static const String boxName = 'categories_v2';
  static const List<String> defaultCategories = ['Genel', 'İş', 'Kişisel'];

  late Box<Category> _box;

  @override
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    _box = await Hive.openBox<Category>(boxName);

    // Box hâlâ boşsa: ya taze bir kurulum (migrate edilecek eski veri yoktu)
    // ya da migration henüz çalışmadı. Migration main.dart'ta bu init()'ten
    // ÖNCE çalıştığı için, box boşsa gerçekten taşınacak veri yok demektir —
    // bu durumda varsayılan kategorileri burada oluşturuyoruz.
    if (_box.isEmpty) {
      for (final name in defaultCategories) {
        final category = Category(id: const Uuid().v4(), name: name);
        await _box.put(category.id, category);
      }
    }
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return _box.values.toList();
  }

  @override
  Future<Category> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Kategori adı boş olamaz.');
    }

    // Aynı isimde kategori zaten varsa yenisini oluşturmadan mevcudu dön.
    final existing = _box.values.where((c) => c.name == trimmed);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final category = Category(id: const Uuid().v4(), name: trimmed);
    await _box.put(category.id, category);
    return category;
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return _box.get(id);
  }

  @override
  Future<void> renameCategory(String id, String newName) async {
    final category = _box.get(id);
    if (category == null) return;
    category.name = newName.trim();
    await category.save();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
  }
}
