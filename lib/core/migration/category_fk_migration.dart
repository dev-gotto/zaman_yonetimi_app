import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/task.dart';

/// Kategori sisteminin düz String'den ID tabanlı (FK) yapıya tek seferlik
/// geçişini yürütür. `main.dart` içinde, repository'ler init edilmeden
/// ÖNCE çağrılmalıdır.
///
/// Çalışma mantığı:
/// 1. Daha önce migrate edildiyse ('meta' box'ındaki flag) hiçbir şey
///    yapmadan çıkar.
/// 2. Eski 'categories' box'ında (Box<String>) kayıtlı kategori isimlerini
///    okur. Bu box hiç var olmamışsa (taze kurulum) taşınacak veri yoktur.
/// 3. Her benzersiz isim için yeni bir Category(id, name) oluşturup
///    'categories_v2' box'ına yazar; isim -> yeni id eşlemesini bir Map'te
///    tutar.
/// 4. 'tasks' box'ındaki (Box<Task>) her görevi gezer; categoryId alanında
///    hâlâ eski kategori adı duruyorsa (migration öncesi veri, çünkü Hive
///    alanı index'e göre okuyup eski string'i olduğu gibi categoryId'ye
///    yerleştirmiş olacak), bunu Map üzerinden gerçek id ile değiştirir.
/// 5. Migration tamamlandı flag'ini 'meta' box'ına yazar.
///
/// Not: Eski 'categories' box'ı silinmiyor, sadece artık kullanılmıyor.
/// Migration'ın stabil çalıştığı bir süre doğrulandıktan sonra ayrı bir
/// temizlik adımında kaldırılması planlanıyor (bkz. README.md).
class CategoryFkMigration {
  static const String metaBoxName = 'meta';
  static const String migratedFlagKey = 'migrated_v2';
  static const String legacyCategoriesBoxName = 'categories';
  static const String newCategoriesBoxName = 'categories_v2';
  static const String tasksBoxName = 'tasks';

  static Future<void> runIfNeeded() async {
    final metaBox = await Hive.openBox<bool>(metaBoxName);
    final alreadyMigrated = metaBox.get(migratedFlagKey, defaultValue: false)!;
    if (alreadyMigrated) {
      // ignore: avoid_print
      print('[CategoryFkMigration] Zaten migrate edilmis, atlaniyor.');
      return;
    }

    // ignore: avoid_print
    print('[CategoryFkMigration] Migration baslatiliyor...');

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    final newCategoriesBox = await Hive.openBox<Category>(
      newCategoriesBoxName,
    );

    final legacyBoxExists = await Hive.boxExists(legacyCategoriesBoxName);
    final Map<String, String> nameToIdMap = {};

    if (legacyBoxExists) {
      final legacyBox = await Hive.openBox<String>(legacyCategoriesBoxName);
      final legacyNames = legacyBox.values.toSet(); // tekrarları ele

      for (final name in legacyNames) {
        // Aynı isimde zaten yeni box'ta bir kategori varsa (örn. migration
        // yarıda kesilip tekrar çalıştıysa) tekrar oluşturma.
        final existing = newCategoriesBox.values.where(
          (c) => c.name == name,
        );
        if (existing.isNotEmpty) {
          nameToIdMap[name] = existing.first.id;
          continue;
        }
        final newCategory = Category(id: const Uuid().v4(), name: name);
        await newCategoriesBox.put(newCategory.id, newCategory);
        nameToIdMap[name] = newCategory.id;
      }

      // ignore: avoid_print
      print(
        '[CategoryFkMigration] ${nameToIdMap.length} kategori tasindi: '
        '${nameToIdMap.keys.toList()}',
      );
    } else {
      // ignore: avoid_print
      print(
        '[CategoryFkMigration] Eski kategori box\'i yok, tasi'
        'nacak veri bulunmuyor (taze kurulum olabilir).',
      );
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    final tasksBoxExists = await Hive.boxExists(tasksBoxName);

    if (legacyBoxExists && tasksBoxExists && nameToIdMap.isNotEmpty) {
      final tasksBox = await Hive.openBox<Task>(tasksBoxName);
      var updatedCount = 0;
      var orphanCount = 0;

      for (final task in tasksBox.values) {
        // Bu noktada task.categoryId alani, Hive index-tabanli okuma
        // sayesinde hala ESKI kategori ADINI tutuyor (field numarasi
        // degismedigi icin eski binary veri sorunsuz okundu).
        final oldCategoryName = task.categoryId;
        final mappedId = nameToIdMap[oldCategoryName];

        if (mappedId != null) {
          task.categoryId = mappedId;
          await task.save();
          updatedCount++;
        } else {
          // Beklenmedik durum: görev, eski kategori box'ında karşılığı
          // olmayan bir isme sahip. Veriyi kaybetmemek için dokunmuyoruz,
          // sadece logluyoruz — elle incelenmesi gerekebilir.
          orphanCount++;
          // ignore: avoid_print
          print(
            '[CategoryFkMigration] UYARI: gorev "${task.title}" icin '
            'eslesen kategori bulunamadi (deger: "$oldCategoryName").',
          );
        }
      }

      // ignore: avoid_print
      print(
        '[CategoryFkMigration] $updatedCount gorev guncellendi, '
        '$orphanCount gorev eslesmeden birakildi.',
      );
    }

    await metaBox.put(migratedFlagKey, true);
    // ignore: avoid_print
    print('[CategoryFkMigration] Migration tamamlandi.');
  }
}
