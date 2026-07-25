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
      category.dart, category.g.dart
    providers/
      task_provider.dart
      category_provider.dart
      repository_provider.dart
      timer_provider.dart
      stats_provider.dart
    repositories/
      task_repository.dart, hive_task_repository.dart
      category_repository.dart, hive_category_repository.dart
    migration/
      category_fk_migration.dart
    services/
      notification_service.dart
  features/
    tasks/
      task_list_screen.dart
      task_detail_screen.dart
    categories/
      category_management_screen.dart
    settings/
      settings_menu_screen.dart
    stats/
      stats_screen.dart
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
4. ✅ **Kategori tam CRUD — kod tarafında tamamlandı VE cihazda doğrulandı:**
   - **Repository katmanı:** Değişmedi — `CategoryRepository.renameCategory`/`deleteCategory` zaten hazırdı (migration aşamasından). `TaskRepository`'ye ayrı bir `isCategoryInUse` metodu **eklenmedi** — bunun yerine mevcut `getAllTasks()` kullanıldı (aşağıya bakın).
   - **Provider katmanı:** `category_provider.dart`'a `DeleteCategoryResult` sınıfı eklendi (`.success()` / `.inUse(usageCount)` factory constructor'ları). `CategoryListNotifier.deleteCategory(id)`, silmeden önce `taskRepositoryProvider.getAllTasks()`'ı çekip `categoryId` eşleşen görev sayısını sayıyor; eşleşme varsa exception fırlatmak yerine `DeleteCategoryResult.inUse(count)` **döndürüyor** (UI try/catch yerine düz `if (!result.success)` ile ayırt ediyor). `renameCategory` değişmedi — FK sayesinde otomatik cascade.
   - **UI katmanı:** Yeni `lib/features/categories/category_management_screen.dart` — kategori listesi, her satırda "✏️ yeniden adlandır" ve "🗑️ sil" butonu, silme öncesi onay dialogu. Silme reddedilirse (`!result.success`) SnackBar ile "Bu kategori N görev tarafından kullanılıyor, silinemez" mesajı gösteriliyor. `task_list_screen.dart`'ın AppBar'ına dişli ikonu eklendi → bu ekrana gidiyor (kullanıcı kararına uygun: ayrı sekme değil, AppBar butonu).
   - **✅ Cihaz testi sonucu (25 Temmuz 2026):** Kullanıcı `flutter run` ile test etti, "herşey çalışıyor" onayı alındı — rename/delete/AppBar navigasyonu sorunsuz. **Sonuç: production-ready kabul edildi.**
5. ✅ **Görev Detay Ekranı (plan dışı, kullanıcı isteğiyle eklendi):**
   - Yeni `lib/features/tasks/task_detail_screen.dart` — bir görevin tüm alanlarını salt-okunur gösteriyor: durum, tarih & saat, kategori, tekrar tipi, açıklama (varsa), oluşturulma tarihi. Şu an sadece **inceleme** amaçlı, düzenleme yok (Task Update aşaması ayrı ele alınacak).
   - `task_list_screen.dart`: **`CheckboxListTile` kaldırıldı**, yerine `leading`'de manuel `Checkbox` olan normal `ListTile` kullanıldı — çünkü bu Flutter sürümünde (3.32.2) `CheckboxListTile`'ın `onTap` parametresi yok (denenip derleme hatası alındı). Satırın geri kalanına dokunma artık `TaskDetailScreen`'i açıyor, checkbox'a dokunma sadece tamamlama durumunu değiştiriyor (checkbox kendi dokunma alanını ayrı yönetiyor, çakışma yok).
   - Subtitle artık çok satırlı: tarih/saat, kategori adı (artık "..." ile kesilmiyor) ve varsa açıklama önizlemesi ayrı satırlarda.
   - **⚠️ Not — kullanılmayan `Tekrar` alanı:** Detay ekranında "Tekrar" satırı `Task.repeat` (`RepeatType.none/daily/weekly/monthly`) alanını gösteriyor, ama bu alanı **ayarlayan hiçbir UI yok** — görev ekleme diyaloğunda tekrar seçici yok, alan her zaman varsayılan `none` kalıyor. Bilinçli olarak kaldırılmadı, ileride gerçek "tekrarlayan görev" özelliği eklenince buraya dönülecek. **Bkz. aşağıdaki "Kullanılmayan" listesi.**
   - **✅ Cihaz testi:** Kullanıcı test etti, çalışıyor.
6. ✅ **Task Update (düzenleme) — kod tarafında tamamlandı:**
   - **Repository düzeltmesi (perf/doğruluk):** `hive_task_repository.dart`'taki `updateTask()`, `task.save()` yerine `_box.put(task.id, task)` kullanacak şekilde değiştirildi. Sebep: düzenleme akışı `addTask` ile aynı pattern'i izleyip aynı id'li ama box'a bağlı OLMAYAN yeni bir `Task` nesnesi kuruyor — `task.save()` sadece box'tan gelen nesnelerde çalışır, yenisinde `HiveError` fırlatırdı. `_box.put()` anahtar eşleşirse sorunsuz overwrite ediyor.
   - **Provider (`task_provider.dart`):** `TaskListNotifier.updateTask(Task task)` eklendi. Performans gözetildi: eski bildirim her durumda iptal ediliyor (ucuz), ama native tarafta daha maliyetli olan `scheduleTaskNotification` (zonedSchedule) **sadece görev tamamlanmamışsa** çağrılıyor — tamamlanmış bir görevi gereksiz yere yeniden planlamıyoruz.
   - **UI (`task_list_screen.dart`):** `_showAddTaskDialog` → `_showTaskDialog(..., {Task? existingTask})` olarak genelleştirildi; `existingTask` verilirse alanlar (başlık/tarih/saat/kategori) mevcut değerlerle dolu geliyor, diyalog başlığı "Görevi Düzenle", buton "Güncelle" oluyor ve `updateTask` çağrılıyor. Diyalogda düzenlenmeyen alanlar (`description`, `repeatType`, `isCompleted`, `createdAt`) güncellenen `Task` nesnesine mevcut görevden aynen kopyalanıyor — aksi halde örn. tamamlanmış bir görevi düzenlemek onu yanlışlıkla "tamamlanmadı"ya döndürebilirdi.
   - Her görev satırına ayrı bir "✏️ düzenle" `IconButton`'ı eklendi (satıra dokunma hâlâ `TaskDetailScreen`'i açıyor, çakışma yok — trailing artık iki buton içeren bir `Row`: düzenle + sayaç).
   - **Küçük perf notu:** Diyalog kapandığında `titleController.dispose()` çağrısı eklendi (`showDialog(...).then(...)`) — sık açılıp kapanan bir widget olduğu için controller sızıntısını önlemek adına.
   - **Bilinen kapsam dışı bırakma:** Düzenleme diyaloğu, ekleme diyaloğuyla aynı kapsamda (başlık/tarih/saat/kategori) tutuldu — `description`/`repeatType` için UI hâlâ yok (bkz. "Kullanılmayan" listesindeki `RepeatType` notu, hâlâ geçerli).
   - **✅ Cihaz testi sonucu (25 Temmuz 2026, `flutter run` ile):** Kullanıcı test etti — konsolda `GUNCELLE BUTONUNA BASILDI` → `GOREV GUNCELLENIYOR` → `scheduleTaskNotification CAGRILDI` → `zonedSchedule BASARIYLA cagrildi` → `updateTask BASARIYLA TAMAMLANDI` akışı sorunsuz tamamlandı, yeni `dueDate`'e göre bildirim doğru şekilde yeniden planlandı. **Sonuç: Task Update production-ready kabul edildi.**
7. ✅ **İstatistik ekranı + Ayarlar menüsü + yapısal refactor — kod tarafında tamamlandı:**
   - **Provider (`lib/core/providers/stats_provider.dart`, yeni):** `taskStatsProvider` — toplam/tamamlanan/bekleyen sayıları ve kategoriye göre dağılımı (`Map<categoryId, count>`) `taskListProvider` üzerinden **tek geçişte (O(N))** hesaplıyor. Düz bir `Provider` (AsyncNotifier değil), Riverpod bağımlılığı değişmediği sürece sonucu otomatik önbellekte tutuyor.
   - **UI (`lib/features/stats/stats_screen.dart`, yeni):** 3 özet kart (Toplam/Tamamlanan/Bekleyen) + kategoriye göre dağılım listesi. Kasıtlı olarak sade (bkz. Çalışma Tarzı Tercihleri — UI cilalaması sona bırakılıyor).
   - **Ayarlar menüsü (`lib/features/settings/settings_menu_screen.dart`, yeni):** AppBar'daki ⚙️ ikonu artık doğrudan Kategori Yönetimi'ne değil, önce bu menüye gidiyor. Menü öğeleri ("Kategorileri Yönet", "İstatistikler") veri-odaklı bir liste (`_SettingsMenuItem`) olarak tanımlı — yeni bir ayarlar/araç ekranı eklemek listeye tek satır eklemek demek, `build()`'e dokunmaya gerek yok. Kullanıcı kararı: AppBar'da ayrı ayrı ikonlar yerine tek giriş noktası (bkz. aşağıdaki "Veri-odaklı config" konvansiyonu).
   - **`main.dart` refactor (yapısal, davranış değişmedi):** `_HomeShellState`'teki sekmeler önceden iki paralel dizide tutuluyordu (`_screens` ekran listesi + ayrı `BottomNavigationBarItem` listesi, index üzerinden eşleşiyordu — biri güncellenip diğeri unutulursa sessiz hata riski vardı). Artık tek bir `_HomeTab` (label+icon+screen) listesi var, aynı veri-odaklı config prensibiyle.
   - **`task_list_screen.dart`:** AppBar bağlantısı `CategoryManagementScreen`'den `SettingsMenuScreen`'e güncellendi, tooltip "Ayarlar" oldu.
   - **⏳ Cihaz testi bekleniyor** — kod tarafı tamamlandı ama henüz `flutter run` ile doğrulanmadı: Ayarlar → Kategorileri Yönet / İstatistikler navigasyonu, istatistik sayılarının doğruluğu, 3 sekmenin (Görevler/Takvim/Sayaç) hâlâ doğru çalıştığı test edilmeli.
8. **Sonraki adım (test sonrası, YENİ SOHBETTE BURADAN BAŞLA):** Proje roadmap'indeki tüm ana aşamalar tamamlandı. Sıradaki iş kullanıcıyla birlikte belirlenecek — adaylar: UI cilalaması (bkz. "Kullanılmayan" listesindeki `RepeatType` notu — gerçek tekrarlayan görev özelliği), debug print temizliği, ya da yeni bir özellik.

## Çalışma Tarzı Tercihleri (yeni sohbette hatırlanacak)

- Kod değişiklikleri **katman bazlı gruplanarak** ilerletiliyor: önce Model + Repository (data katmanı, migration dahil) bir arada tamamlanıyor, sonra Provider (controller), en son UI (view). Her katman kendi içinde bitirilip bir sonrakine geçiliyor.
- Büyük/riskli işlerde (migration gibi) **önce yazılı plan sunulup onay alınıyor**, onaydan sonra kodlanıyor.
- Kod değişiklikleri çalışma dosyasında (bu ortamda) yazılıp zip/dosya olarak teslim ediliyor; **push işlemini kullanıcı kendisi yapıyor** (yazma erişimi yok, sadece public repo okuma erişimi var).
- **⚠️ Teslim biçimi — birden fazla dosya değiştiyse tek tek değil, dizin yapısını koruyan TEK bir zip halinde verilecek:** Bir seferinde değişen dosyalar (`README.md`, `lib/core/...`, `lib/features/...`) ayrı ayrı sunulmuştu; kullanıcı arayüzü bunları indirirken hepsini düz (klasörsüz) tek bir `files.zip`'e paketleyince kullanıcı yanlışlıkla hepsini proje köküne çıkarmış, dosyalar `lib/...` altına gitmemiş. Bunun tekrarlanmaması için: birden fazla dosya değiştiğinde, önce doğru göreli yol yapısıyla (`lib/core/repositories/...`, `lib/core/providers/...` vb.) bir klasör ağacı kurulacak, sonra bu ağaç tek bir zip'e paketlenip öyle teslim edilecek — kullanıcı zip'i proje köküne çıkarınca dosyalar otomatik doğru yerlere gitsin. Tek dosya değiştiyse (örn. sadece README) doğrudan o dosya yeterli, zip'e gerek yok.
- Debug `print()` satırlarına dokunulmuyor (yukarıdaki "Kod Stili" bölümüne bakın).
- Kullanılmayan/temizlik bekleyen öğeler bir listede tutulup proje bitiminde toplu temizleniyor (yukarıdaki ilgili bölüme bakın).
- **Performans ve yapı önce, UI cilalaması en sona:** Katman bazlı ilerlerken UI'ı bilinçli olarak en son ve en sade haliyle bırakıyoruz (`category_management_screen.dart` ve `stats_screen.dart`'taki "kasıtlı olarak sade tutuldu" notları bunun içindir). Öncelik sırası: (1) veri/repository katmanının doğruluğu, (2) performans (gereksiz native çağrı / gereksiz O(N) tarama gibi maliyetlerden kaçınmak — bkz. `stats_provider.dart`'taki tek geçiş hesaplama, `task_provider.dart`'taki koşullu bildirim yeniden planlama), (3) yapısal sağlamlık (bkz. aşağıdaki veri-odaklı config maddesi), (4) en son görsel/UX cilalaması. Yeni bir özellik önerilirken de bu sırayla yaklaşılacak.
- **Veri-odaklı config, paralel dizi/hardcode yerine:** Birden fazla benzer öğe (menü satırları, sekmeler, vb.) tanımlanırken, ilgili alanlar (başlık+ikon+hedef gibi) TEK bir veri nesnesinde ("çocuk nesne") birleştirilip bir liste üzerinden `.map()`/`ListView.builder`/`for` ile render ediliyor — birbirinden bağımsız güncellenebilen paralel diziler (ör. eskiden `main.dart`'taki ayrı `_screens` ve `BottomNavigationBarItem` listeleri, index üzerinden sessizce senkron kalması gereken) kullanılmıyor. Örnekler: `settings_menu_screen.dart`'taki `_SettingsMenuItem` listesi, `main.dart`'taki `_HomeTab` listesi. Yeni bir menü/sekme/liste eklerken bu pattern'e uyulacak.
- **⚠️ Repo durumu kontrolü — GitHub'ın render edilmiş HTML sayfasına güvenilmeyecek:** Bir oturumda, GitHub'ın normal repo sayfası (`github.com/dev-gotto/zaman_yonetimi_app`) üzerinden okunan README içeriği önbellekten bayat çıktı — Kategori CRUD ve Görev Detay Ekranı gibi zaten tamamlanmış işler "henüz yapılmadı" gibi göründü. Bunun tekrarlanmaması için: yeni bir sohbette repo/README durumu kontrol edilirken **ham (raw) içerik** kullanılmalı, render edilmiş sayfa değil. Örnek yollar:
  - `https://raw.githubusercontent.com/dev-gotto/zaman_yonetimi_app/main/README.md` (tek dosya için)
  - `https://codeload.github.com/dev-gotto/zaman_yonetimi_app/tar.gz/refs/heads/main` (tüm repo ağacı için, tarball indirip açarak)
  - Şüphe varsa ikisini karşılaştır; render edilmiş sayfadaki içerik ham içerikle çelişiyorsa ham içerik esas alınacak.

## Kod Stili / Kasıtlı Kararlar (henüz temizlenmeyecek)

- `task_provider.dart`, `task_list_screen.dart`, `notification_service.dart` içinde bolca `// ignore: avoid_print` ile işaretlenmiş debug `print()` satırı var. **Bu kasıtlı** — geliştirme sürecinde bildirim/zamanlama gibi debug'ı zor konularda iz sürmek için bırakılıyor. **Proje bitiminde toplu olarak temizlenecek, o zamana kadar dokunulmayacak.**
- Yeni kod eklerken bu tarzı bozmaya gerek yok; istersen aynı debug-print pattern'iyle devam edebiliriz.

## Kullanılmayan / Temizlik Bekleyen Öğeler

> Proje bitiminde topluca gözden geçirilecek liste. Yeni bir şey fark edildikçe buraya eklenecek.

- ✅ `lib.rar` — silindi, repodan kalktığı doğrulandı.
- `dizin_yarat.bat` — işlevi netleşmedi, projeye gerçekten gerekli mi kontrol edilecek.
- Eski `categories` box'ı (`Box<String>`) — kategori-FK migration'ı sonrası kod tarafından artık kullanılmıyor (yerini `categories_v2` aldı), ama geri dönüş payı için hemen silinmedi. Migration'ın birkaç gerçek kullanımda stabil çalıştığı doğrulandıktan sonra hem bu box'ı silen hem de `category_fk_migration.dart` dosyasını kaldıran bir temizlik adımı atılacak.
- ⚠️ **`Task.repeatType` / `RepeatType` enum — DİKKAT: bu, diğer maddelerin aksine silinecek bir öğe DEĞİL.** Model ve `task_detail_screen.dart`'ta gösteriliyor ama bu değeri ayarlayan hiçbir UI yok (görev ekleme diyaloğunda tekrar seçici yok), o yüzden şu an her görevde sabit "Yok" (`none`) görünüyor. Gelecekte gerçek "tekrarlayan görev" özelliği yapılacaksa buradan devam edilecek — buraya not düşüldü ki unutulmasın. Proje sonu temizliğinde kaldırılmayacak, aksine tamamlanması gereken bir özellik olarak değerlendirilecek.

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
