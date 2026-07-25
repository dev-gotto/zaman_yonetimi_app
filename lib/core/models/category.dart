import 'package:hive/hive.dart';

part 'category.g.dart';

/// Kategori-FK migration'ının bir parçası olarak eklendi.
/// Öncesinde kategoriler düz String olarak saklanıyordu; artık Task modeli
/// gibi kendi `id`'sine sahip, Task.categoryId üzerinden referans alınıyor.
@HiveType(typeId: 1) // Task modeli typeId=0 kullanıyor, çakışmasın diye 1
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  Category({required this.id, required this.name});
}
