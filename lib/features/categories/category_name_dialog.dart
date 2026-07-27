import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/category.dart';
import '../../core/providers/category_provider.dart';

/// Kategori adı girmek için tek metin alanlı, tek amaçlı diyalog.
/// `existingCategory` verilirse yeniden adlandırma modunda çalışır,
/// verilmezse yeni kategori oluşturur.
///
/// **Neden ConsumerStatefulWidget (ve neden ayrı, paylaşılan bir dosya):**
/// Bu proje daha önce üç ayrı yerde (görev formu, kategori ekleme, kategori
/// yeniden adlandırma) aynı hatayı üç kez yaşadı: TextEditingController'ın
/// dispose()'u, showDialog()'un döndürdüğü dış bir Future'a
/// (`.then()`/`.whenComplete()`/manuel `finally`) bağlıydı. Ekleme/yeniden
/// adlandırma işlemi bir Riverpod state güncellemesi tetikliyor
/// (categoryListProvider/taskListProvider), bu güncelleme paylaşılan bir üst
/// context (ör. ProviderScope) üzerinden diyaloğun HÂLÂ kapanış animasyonu
/// süren widget'ını yeniden build etmeye zorlayabiliyor — dış Future o ana
/// kadar zaten tamamlanmış ve controller disposed olmuş oluyor. Sonuç:
/// "TextEditingController was used after being disposed" ve ardından gelen
/// Element/build-scope assertion'ları (gerçek cihazda üç kez doğrulandı).
///
/// Kesin çözüm: controller'ın ömrünü, dış bir Future'ın tamamlanma ANINA
/// değil, widget'ın kendi initState/dispose yaşam döngüsüne (yani Element
/// gerçekten unmount edilene) bağlamak. Bunu TEK bir paylaşılan widget'ta
/// yapıp üç ayrı kullanım yerinin de buna yönlendirilmesi, aynı hatanın
/// dördüncü bir yerde tekrar yazılmasını da önlüyor.
class CategoryNameDialog extends ConsumerStatefulWidget {
  final String title;
  final String confirmLabel;
  final Category? existingCategory;

  const CategoryNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.existingCategory,
  });

  @override
  ConsumerState<CategoryNameDialog> createState() =>
      _CategoryNameDialogState();
}

class _CategoryNameDialogState extends ConsumerState<CategoryNameDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.existingCategory?.name ?? '',
    );
  }

  @override
  void dispose() {
    // Bu widget'ın kendi Element'i unmount edilirken tetiklenir — dış bir
    // Future'a bağlı değil, bu yüzden "hâlâ kapanış animasyonu süren
    // diyaloğu bir üst context yeniden build etmeye çalışıyor ama controller
    // zaten disposed" yarış durumu artık mümkün değil.
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(categoryListProvider.notifier);
    Category? resultCategory;

    if (widget.existingCategory != null) {
      await notifier.renameCategory(widget.existingCategory!.id, name);
    } else {
      resultCategory = await notifier.addCategory(name);
    }

    // Diyalog kapanmadan önce hâlâ ağaçta olduğumuzdan emin ol.
    if (!mounted) return;
    // Ekleme modunda oluşturulan Category'yi çağırana döndürüyoruz — görev
    // formu gibi bazı çağıranlar dropdown'da hemen seçili hale getirmek için
    // buna ihtiyaç duyuyor. Yeniden adlandırmada id değişmediği için
    // çağıranın zaten elinde olan id yeterli, bu yüzden null dönüyoruz.
    Navigator.pop(context, resultCategory);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Kategori adı'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
