# Zaman Yönetimi + CRM Uygulaması (Flutter)

> Bu dosya, projeye herhangi bir yeni sohbette (Claude ile) kaldığı yerden devam edebilmek için tutulan **canlı durum belgesidir**. Her önemli değişiklikten sonra güncellenir. Yeni bir sohbete başlarken sadece bu repoyu ve bu dosyayı paylaşman yeterli — ayrıca özet yapıştırmana gerek yok.

## Ortam

- OS: Windows
- Flutter: 3.32.2
- Dart SDK: ^3.8.1
- RAM: 8 GB (performans kısıtı — build_runner / flutter run zaman zaman yavaş olabilir)
- Cihaz bağlantısı: Kablosuz ADB
- Proje yolu (local): `E:\_Project Reserve\Proje\Flutter\GitHub\zaman_yonetimi_app`
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
3. ✅ **Kategori-FK Migration — kod tarafında tamamlandı VE cihazda doğrulandı:**
   - `Category` modeli eklendi (`lib/core/models/category.dart` + `category.g.dart`, `typeId: 1`).
   - `Task.category` (String) → `Task.categoryId` (String, FK) oldu. Alan numarası (`@HiveField(6)`) kasıtlı olarak değiştirilmedi — eski binary veriyle uyumluluk için.
   - `CategoryRepository` arayüzü genişledi: `addCategory` artık `Category` döner, ayrıca `getCategoryById`, `renameCategory`, `deleteCategory` eklendi (rename/delete'in UI'ı henüz yok, altyapı hazır).
   - `HiveCategoryRepository` artık `categories_v2` box'ında (`Box<Category>`) çalışıyor. Eski `categories` box'ı (`Box<String>`) hâlâ diskte ama artık kullanılmıyor.
   - **Migration mantığı** yeni bir dosyada: `lib/core/migration/category_fk_migration.dart` → `CategoryFkMigration.runIfNeeded()`. `main.dart`'ta repository init'lerinden ÖNCE çağrılıyor. Tek seferlik çalışır (`meta` box'ında `migrated_v2` flag'i ile korunuyor), eski kategori isimlerini yeni ID'li `Category` kayıtlarına çevirir ve mevcut görevlerin `categoryId` alanını günceller. Eşleşmeyen (orphan) görevler dokunulmadan bırakılıp loglanıyor.
   - `category_provider.dart` artık `List<Category>` state tutuyor; ayrıca `categoryByIdProvider` eklendi (UI'da `categoryId` → isim lookup için).
   - `task_list_screen.dart` güncellendi: dropdown artık kategori id'si üzerinden çalışıyor, görev satırındaki alt metinde kategori adı `categoryByIdProvider` ile gösteriliyor.
   - **⚠️ Önemli — build_runner:** `category.g.dart` bu ortamda `build_runner` çalıştırılamadığı için `task.g.dart`'taki pattern birebir takip edilerek elle yazıldı. Cihazda gerçek verilerle sorunsuz migration+CRUD çalıştığı doğrulandı, dolayısıyla adapter'ın doğru üretildiği fiilen kanıtlandı. Yine de fırsat bulunca aşağıdaki komutla resmi codegen çıktısıyla eşleştiği teyit edilebilir:
     ```
     flutter pub run build_runner build --delete-conflicting-outputs
     ```
   - **Gerçek cihaz testi sonucu (25 Temmuz 2026, `flutter run` ile):**
     - [x] Var olan (migration öncesi) görevler doğru kategorileriyle görüntülendi.
     - [x] Migration ilk açılışta çalıştı — konsol: `5 kategori tasindi: [Genel, İş, Kişisel, testing IV, yeni kategori]`, `5 gorev guncellendi, 0 gorev eslesmeden birakildi.` **0 orphan — veri kaybı yok.**
     - [x] Uygulama telefonda tamamen kapatılıp tekrar açıldığında sorunsuz çalıştı (bu, `flutter run` debug köprüsünden bağımsız bir açılış olduğu için konsol logu görünmedi, ama migration flag kontrolünün hataya yol açmadığının dolaylı kanıtı — çökme/hata olsaydı uygulama açılmazdı).
     - [x] Yeni görev eklerken kategori dropdown'u ve "yeni kategori ekle" akışı sorunsuz çalıştı.
     - [x] `flutter run` ile tam derleme yapıldı (Gradle build başarılı, APK cihaza kuruldu).
   - **Sonuç: Migration production-ready kabul edildi.** Sıradaki adımlara geçilebilir.
4. ✅ **Kategori tam CRUD — kod tarafında tamamlandı (cihaz testi bekliyor):**
   - **Repository katmanı:** `TaskRepository`'ye `isCategoryInUse(String categoryId)` eklendi (soyut arayüz + `HiveTaskRepository` implementasyonu). `CategoryRepository.renameCategory`/`deleteCategory` zaten hazırdı, değişmedi.
   - **Provider katmanı:** `CategoryListNotifier.deleteCategory`, silmeden önce `taskRepositoryProvider` üzerinden çapraz kontrol yapıyor — kategori bir görev tarafından kullanılıyorsa `CategoryInUseException` fırlatıyor (kullanılmıyorsa siliniyor). `renameCategory` zaten hazırdı (FK sayesinde otomatik cascade — Task'lar `categoryId` üzerinden referans verdiği için ekstra güncelleme gerekmiyor).
   - **UI katmanı:** Yeni `lib/features/categories/category_management_screen.dart` — kategori listesi, her satırda "✏️ yeniden adlandır" ve "🗑️ sil" butonu. Silme, `CategoryInUseException` yakalanıp SnackBar ile kullanıcıya gösteriliyor. `task_list_screen.dart`'ın AppBar'ına dişli ikonu eklendi → bu ekrana gidiyor (kullanıcı kararına uygun: ayrı sekme değil, AppBar butonu).
   - **⏳ Sıradaki adım — cihaz testi (YENİ SOHBETTE BURADAN BAŞLA):**
     - [ ] Rename: bir kategoriyi yeniden adlandır, görev listesindeki subtitle'da adın otomatik değiştiğini doğrula (FK cascade kanıtı).
     - [ ] Delete (kullanımda değil): kullanılmayan bir kategoriyi sil, listeden kalktığını doğrula.
     - [ ] Delete (kullanımda): bir göreve atanmış kategoriyi silmeyi dene, SnackBar hatası çıktığını ve kategori silinmediğini doğrula.
     - [ ] `flutter run` ile tam derleme (hot reload değil — yeni dosya eklendi).
   - Test checklist geçilirse: **Sonra: Task Update (düzenleme).** Her görev satırına ayrı bir "✏️ düzenle" ikonu/butonu eklenecek (satıra dokunma değil, ayrı buton — kullanıcı kararı). Mevcut "Yeni Görev" diyaloğu yeniden kullanılacak, alanlar mevcut değerlerle dolu gelecek, "Güncelle" butonu olacak.
   - **En son: İstatistik ekranı** (tamamlanan/bekleyen görev sayıları, kategoriye göre dağılım — FK sayesinde bu kolaylaşacak).

## Çalışma Tarzı Tercihleri (yeni sohbette hatırlanacak)

- Kod değişiklikleri **katman bazlı gruplanarak** ilerletiliyor: önce Model + Repository (data katmanı, migration dahil) bir arada tamamlanıyor, sonra Provider (controller), en son UI (view). Her katman kendi içinde bitirilip bir sonrakine geçiliyor.
- Büyük/riskli işlerde (migration gibi) **önce yazılı plan sunulup onay alınıyor**, onaydan sonra kodlanıyor.
- Kod değişiklikleri çalışma dosyasında (bu ortamda) yazılıp zip/dosya olarak teslim ediliyor; **push işlemini kullanıcı kendisi yapıyor** (yazma erişimi yok, sadece public repo okuma erişimi var).
- Debug `print()` satırlarına dokunulmuyor (yukarıdaki "Kod Stili" bölümüne bakın).
- Kullanılmayan/temizlik bekleyen öğeler bir listede tutulup proje bitiminde toplu temizleniyor (yukarıdaki ilgili bölüme bakın).

## Kod Stili / Kasıtlı Kararlar (henüz temizlenmeyecek)

- `task_provider.dart`, `task_list_screen.dart`, `notification_service.dart` içinde bolca `// ignore: avoid_print` ile işaretlenmiş debug `print()` satırı var. **Bu kasıtlı** — geliştirme sürecinde bildirim/zamanlama gibi debug'ı zor konularda iz sürmek için bırakılıyor. **Proje bitiminde toplu olarak temizlenecek, o zamana kadar dokunulmayacak.**
- Yeni kod eklerken bu tarzı bozmaya gerek yok; istersen aynı debug-print pattern'iyle devam edebiliriz.

## Kullanılmayan / Temizlik Bekleyen Öğeler

> Proje bitiminde topluca gözden geçirilecek liste. Yeni bir şey fark edildikçe buraya eklenecek.

- ✅ `lib.rar` — silindi, repodan kalktığı doğrulandı.
- `dizin_yarat.bat` — işlevi netleşmedi, projeye gerçekten gerekli mi kontrol edilecek.
- Eski `categories` box'ı (`Box<String>`) — kategori-FK migration'ı sonrası kod tarafından artık kullanılmıyor (yerini `categories_v2` aldı), ama geri dönüş payı için hemen silinmedi. Migration'ın birkaç gerçek kullanımda stabil çalıştığı doğrulandıktan sonra hem bu box'ı silen hem de `category_fk_migration.dart` dosyasını kaldıran bir temizlik adımı atılacak.

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

## Kategori-FK Migration Planı (✅ uygulandı — referans için saklanıyor)

> Bu bölüm, migration'ın nasıl planlandığını ve hangi sırayla uygulandığını gösteriyor. Kod tarafında tamamlandı; kalan iş yukarıdaki "Test checklist" maddeleri.

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
