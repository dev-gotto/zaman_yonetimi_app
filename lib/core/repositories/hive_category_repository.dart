import 'package:hive_flutter/hive_flutter.dart';
import 'category_repository.dart';

class HiveCategoryRepository implements CategoryRepository {
  static const String boxName = 'categories';
  static const List<String> defaultCategories = ['Genel', 'İş', 'Kişisel'];

  late Box<String> _box;

  @override
  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
    if (_box.isEmpty) {
      for (final category in defaultCategories) {
        await _box.add(category);
      }
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    return _box.values.toList();
  }

  @override
  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_box.values.contains(trimmed)) return;
    await _box.add(trimmed);
  }
}