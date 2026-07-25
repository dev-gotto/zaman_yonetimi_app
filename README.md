# Zaman Yönetimi + CRM Uygulaması (Flutter)

> Bu dosya, projeye herhangi bir yeni sohbette (Claude ile) kaldığı yerden devam edebilmek için tutulan **canlı durum belgesidir**. Her önemli değişiklikten sonra güncellenir. Yeni bir sohbete başlarken sadece bu repoyu ve bu dosyayı paylaşman yeterli — ayrıca özet yapıştırmana gerek yok.

## Ortam

- OS: Windows
- Flutter: 3.32.2
- Dart SDK: ^3.8.1
- RAM: 8 GB (performans kısıtı — build_runner / flutter run zaman zaman yavaş olabilir)
- Cihaz bağlantısı: Kablosuz ADB
- Proje yolu (local): `E:\_Project Reserve\Proje\Flutter\APP\zaman_yonetimi_app`
- Repo: https://github.com/dev-gotto/zaman_yonetimi_app

**Bilinen kısıtlamalar:**
- Debug/profile modda bazı native özellikler (örn. exact alarm, bildirim davranışları) release moddan farklı çalışabiliyor — test ederken bunu göz önünde bulundur.
- Yeni bir dosya eklendiğinde **hot reload yeterli değil**, tam `flutter run` yapılmalı.
- Sadece mevcut Dart dosyalarında değişiklik yapıldıysa `flutter clean` gerekmiyor.
- Yeni bir Hive `@HiveType` eklendiğinde veya alan yapısı değiştiğinde `build_runner` çalıştırılmalı:
  ```
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

## Teknik Mimari

- **State management:** Riverpod v3.3.2 (`Notifier` / `AsyncNotifier`)
- **Veritabanı:** Hive, repository pattern uygulanıyor — `lib/core/providers/repository_provider.dart` DB implementasyonunu değiştirmek istediğimizde **tek değişecek nokta** olacak şekilde tasarlandı
- **Bildirimler:** `flutter_local_notifications` + `timezone` + `flutter_timezone`

## Proje Yapısı (özet)

```
lib/
  core/
    models/
      task.dart, task.g.dart
    providers/
      task_provider.dart
      category_provider.dart
      repository_provider.dart
      timer_provider.dart
    repositories/
      task_repository.dart, hive_task_repository.dart
      category_repository.dart, hive_category_repository.dart
    services/
      notification_service.dart
  features/
    tasks/
      task_list_screen.dart
    calendar/
      calendar_screen.dart
    timer/
      timer_screen.dart
  main.dart
```

## Tamamlanan Aşamalar

### ✅ 1-3. Aşama
- Temel CRUD (görev ekleme/silme/tamamlama)
- Takvim entegrasyonu (`table_calendar`)
- Alarm & bildirim motoru (zamanlanmış bildirimler, exact alarm izinleri, Durdur/Ertele aksiyonları)

### ✅ 4. Aşama — Sayaç/Timer
- `lib/core/providers/timer_provider.dart`: `TimerNotifier` (Riverpod `Notifier`), hem Geri Sayım hem Kronometre modu destekliyor. Opsiyonel `taskId`/`taskTitle` ile hem bağımsız hem göreve bağlı kullanılabiliyor.
- `lib/features/timer/timer_screen.dart`: tek ekran — `task` parametresi null ise genel sekme, doluysa göreve bağlı sayaç.
- `main.dart`'a 3. sekme ("Sayaç") eklendi.
- `task_list_screen.dart`'taki her görev satırına "▶" (play_circle_outline) butonu eklendi → o göreve bağlı sayaç açıyor.
- `notification_service.dart`'a `showInstantNotification()` eklendi (sayaç bittiğinde anlık bildirim).
- **Bilinen sınırlama:** Aynı anda sadece bir sayaç çalışabiliyor (minimum kapsam, kasıtlı olarak sonraya bırakıldı).

### 🔶 5. Aşama — İstatistik, kategori yönetimi, cilalama (DEVAM EDİYOR)

1. ✅ Görev listesi sıralama bugı düzeltildi — `hive_task_repository.dart`'ta `getAllTasks()` ve `getTasksByDate()` artık `dueDate`'e göre artan sırada dönüyor (önceden Hive'ın rastgele iç sırasına göre görünüyordu).
2. ✅ Kategori yönetimi — temel (Create + Read):
   - `lib/core/repositories/category_repository.dart` (soyut) + `hive_category_repository.dart` (somut). Varsayılan kategoriler: `Genel`, `İş`, `Kişisel`.
   - `lib/core/providers/category_provider.dart` — `CategoryListNotifier` (`AsyncNotifier`).
   - `repository_provider.dart`'a `categoryRepositoryProvider` eklendi.
   - `main.dart`'ta kategori repository'si de init ediliyor.
   - `task_list_screen.dart`'taki görev ekleme diyaloğuna kategori dropdown + "yeni kategori ekle" butonu eklendi, seçilen kategori göreve kaydediliyor.
3. ⚠️ **AKTİF İŞ — Kategori-FK Migration (şu an üzerinde çalışılıyor):**
   - **Sorun:** `Task.category` alanı düz `String` olarak saklanıyor, kategori tablosuyla ID bazlı (FK) ilişkisi yok. Kategori yeniden adlandırıldığında bu değişiklik görevlere otomatik yansımıyor.
   - **Karar:** `Category` modeli kendi `id`'sine sahip olacak (Task modeli gibi, yeni `@HiveType`, `typeId: 1`). `Task.category` (String) yerine `Task.categoryId` (String, FK → `Category.id`) kullanılacak.
   - **Migration riski:** Mevcut `HiveCategoryRepository`'de kategoriler düz string olarak `Box<String>` içinde tutuluyor, ID yok. Bu, ID'li `Category` modeline dönüştürülecek. `Task.category` (String) alanı `Task.categoryId` (String, FK) olacak — **var olan Hive verisiyle uyumluluk (migration) gerektiriyor, dikkatli yapılmalı** (aşağıdaki "Migration Planı" bölümüne bakın).
   - Detaylı adım adım plan bu dosyanın en altındaki "Kategori-FK Migration Planı" bölümünde.
4. ⏳ Sıradaki adımlar (henüz yapılmadı, plan netleşti — migration bitince sırayla yapılacak):
   - **Task Update (düzenleme):** Her görev satırına ayrı bir "✏️ düzenle" ikonu/butonu eklenecek (satıra dokunma değil, ayrı buton — kullanıcı kararı). Mevcut "Yeni Görev" diyaloğu yeniden kullanılacak, alanlar mevcut değerlerle dolu gelecek, "Güncelle" butonu olacak.
   - **Kategori tam CRUD:** Yeniden adlandırma (rename — FK sayesinde otomatik cascade olacak) + silme (bir kategori herhangi bir görev tarafından kullanılıyorsa silinemeyecek, kullanım sayısı FK üzerinden kontrol edilecek).
   - **"Kategorileri Yönet" ekranı:** `task_list_screen.dart`'ın AppBar'ına bir ayarlar/seçenekler ikonu eklenecek (sağ üstte, üç nokta veya dişli ikonu gibi), oradan bu yönetim ekranına gidilecek — kullanıcı kararı: ayrı bir sekme değil, AppBar'da bir buton.
   - Bunlardan sonra: **İstatistik ekranı** (tamamlanan/bekleyen görev sayıları, kategoriye göre dağılım — FK sayesinde bu kolaylaşacak).

## Kod Stili / Kasıtlı Kararlar (henüz temizlenmeyecek)

- `task_provider.dart`, `task_list_screen.dart`, `notification_service.dart` içinde bolca `// ignore: avoid_print` ile işaretlenmiş debug `print()` satırı var. **Bu kasıtlı** — geliştirme sürecinde bildirim/zamanlama gibi debug'ı zor konularda iz sürmek için bırakılıyor. **Proje bitiminde toplu olarak temizlenecek, o zamana kadar dokunulmayacak.**
- Yeni kod eklerken bu tarzı bozmaya gerek yok; istersen aynı debug-print pattern'iyle devam edebiliriz.

## Kullanılmayan / Temizlik Bekleyen Öğeler

> Proje bitiminde topluca gözden geçirilecek liste. Yeni bir şey fark edildikçe buraya eklenecek.

- `lib.rar` — eski/yedek bir `lib/` klasörü arşivi, repo kökünde duruyor. Kullanıcı tarafından local'de silindi ancak henüz commit/push edilmedi — bir sonraki push'ta repodan kalkması gerekiyor.
- `dizin_yarat.bat` — işlevi netleşmedi, projeye gerçekten gerekli mi kontrol edilecek.
- (Migration sonrası) Eski `categories` box'ı (`Box<String>`) — yeni ID'li box'a geçişten sonra kod tarafından kullanılmayacak ama geri dönüş payı için hemen silinmeyecek, migration stabil olduğu doğrulandıktan sonra kaldırılacak.

## pubspec.yaml — Ana Bağımlılıklar

```yaml
flutter_riverpod: ^3.3.2
hive: ^2.2.3
hive_flutter: ^1.1.0
uuid: ^4.6.0
path_provider: ^2.1.5
table_calendar: ^3.1.2
flutter_local_notifications: ^18.0.1
timezone: ^0.9.4
flutter_timezone: ^5.0.1

dev:
  hive_generator: ^2.0.1
  build_runner: ^2.5.4
```

---

## Kategori-FK Migration Planı (aktif iş — detaylı)

**Hedef:** `Task.category` (String) → `Task.categoryId` (String, FK), `Category` modeli kendi `id`'sine sahip olacak, rename otomatik cascade olacak.

1. **Yeni `Category` Hive Modeli** — `lib/core/models/category.dart` (+ üretilecek `category.g.dart`)
   ```dart
   @HiveType(typeId: 1)   // Task typeId=0 kullanıyor, çakışmasın diye 1
   class Category extends HiveObject {
     @HiveField(0) String id;
     @HiveField(1) String name;
   }
   ```

2. **`CategoryRepository` arayüzünün genişletilmesi**
   - Şu an: `getAllCategories() → List<String>`, `addCategory(String)`
   - Yeni: `getAllCategories() → List<Category>`, `addCategory(String name) → Category`, `renameCategory(String id, String newName)`, `deleteCategory(String id)` (kullanım kontrolüyle), `getCategoryById(String id) → Category?`

3. **`Task` modelinde değişiklik**
   - `@HiveField(6) String category` → `@HiveField(6) String categoryId`
   - Alan numarası (6) **aynı kalacak** — Hive field index'e göre okuduğu için eski binary veriyle uyumluluk açısından önemli.

4. **Migration adımı (veri kaybı riski burada, dikkatli yapılacak)**
   - `main.dart` içinde `_AppInitializer` başlamadan önce bir kerelik çalışacak.
   - Eski `categories` box'ını (`Box<String>`) aç, mevcut string listesini oku.
   - Her string için `Category(id: uuid, name: eskiString)` oluştur, yeni box'a (`categories_v2`, `Box<Category>`) yaz.
   - String→id eşleşme haritası oluştur.
   - `tasks` box'ındaki her Task'ı gez, `task.category` (eski string) değerini haritadan bulup `task.categoryId`'ye ata, `task.save()`.
   - Migration'ın tekrar çalışmaması için bir flag kaydet (Hive'da basit bir `meta` box'ında `migrated_v2: true`).
   - Eski `categories` box'ı **hemen silinmeyecek**, sadece kullanılmayacak (geri dönüş payı).

5. **Etkilenen diğer dosyalar**
   - `category_provider.dart` → state `List<String>` yerine `List<Category>` olacak.
   - `task_list_screen.dart` → dropdown artık `Category.name` gösterip `Category.id` seçecek; satırdaki subtitle'da kategori adını göstermek için `categoryId`'den `Category` bulma (provider üzerinden basit lookup).
   - `repository_provider.dart` → değişmeyecek (sadece interface genişliyor).

6. **Uygulama sırası**
   1. Category modeli + adapter
   2. CategoryRepository interface + Hive implementasyonu (yeni metodlarla)
   3. Migration kodu (`main.dart`'a eklenecek)
   4. Task modelinde `categoryId`'ye geçiş
   5. Provider'lar
   6. UI (`task_list_screen.dart`) güncellemesi
   7. `flutter run` ile test (hot reload değil — yeni Hive tipi eklendiği için şart)
