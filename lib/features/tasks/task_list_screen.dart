import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/task.dart';
import '../../core/models/category.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/category_provider.dart';
import '../timer/timer_screen.dart';
import '../settings/settings_menu_screen.dart';
import '../categories/category_name_dialog.dart';
import 'task_detail_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Görevlerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsMenuScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('Henüz görev yok. + ile ekle.'));
          }
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                background: Container(color: Colors.red),
                onDismissed: (_) {
                  ref.read(taskListProvider.notifier).deleteTask(task.id);
                },
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                  // Not: Bu Flutter sürümünde CheckboxListTile'ın onTap
                  // parametresi yok (derleme hatası verdi), bu yüzden
                  // leading'e manuel bir Checkbox koyup normal ListTile
                  // kullanıyoruz — Checkbox kendi dokunma alanını ayrı
                  // yönettiği için satırın geri kalanına dokunma detay
                  // ekranını açar, checkbox'a dokunma sadece tamamlama
                  // durumunu değiştirir.
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) {
                      ref
                          .read(taskListProvider.notifier)
                          .toggleComplete(task.id);
                    },
                  ),
                  title: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} '
                        '${task.dueDate.hour.toString().padLeft(2, '0')}:'
                        '${task.dueDate.minute.toString().padLeft(2, '0')}',
                      ),
                      Text(
                        // Kategori adı artık tam gösteriliyor (ellipsis yok) —
                        // liste ekranında kesilerek okunamaz hale gelmesin diye.
                        categoryById[task.categoryId]?.name ??
                            'Bilinmeyen kategori',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description != null &&
                          task.description!.trim().isNotEmpty)
                        Text(
                          task.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Görevi düzenle',
                        onPressed: () => _showTaskDialog(
                          context,
                          ref,
                          categoriesAsync.value ?? const [],
                          existingTask: task,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.play_circle_outline),
                        tooltip: 'Bu görev için sayaç başlat',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TimerScreen(task: task),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(
          context,
          ref,
          categoriesAsync.value ?? const [],
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  // existingTask verilirse ekleme yerine düzenleme modunda açılır: alanlar
  // mevcut değerlerle dolu gelir, "Ekle" yerine "Güncelle" gösterilir ve
  // kaydetme taskListProvider.updateTask'i çağırır. Aynı diyaloğun hem
  // ekleme hem düzenleme için kullanılması, iki ayrı dialog'u senkron
  // tutma yükünü (performans + bakım açısından) ortadan kaldırıyor.
  //
  // Not (düzeltme, 28 Temmuz 2026): Bu diyalog önceden showDialog + harici
  // bir TextEditingController + StatefulBuilder kombinasyonuyla yazılıyordu,
  // controller'ın dispose()'u showDialog()'un döndürdüğü Future'a
  // (`.then(...)`) bağlıydı. Görev güncellendiğinde dueDate değiştiği için
  // liste yeniden sıralanıyor, bu da TaskListScreen'i (üst ağacı) tam
  // diyalog kapanış animasyonu sürerken rebuild ediyordu — controller bazen
  // bu rebuild tamamlanmadan disposed oluyor ve "TextEditingController was
  // used after being disposed" + ardından gelen Element/build-scope
  // assertion'larına yol açıyordu. Artık form içeriği kendi
  // initState/dispose'una sahip bir StatefulWidget (_TaskFormDialog) —
  // controller'ın ömrü widget'ın kendi yaşam döngüsüne (Element unmount
  // sırasına) bağlı, dış bir Future zamanlamasına değil. Bu, yarış
  // durumunu kökten ortadan kaldırıyor.
  void _showTaskDialog(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories, {
    Task? existingTask,
  }) {
    showDialog(
      context: context,
      builder: (context) => _TaskFormDialog(
        ref: ref,
        categories: categories,
        existingTask: existingTask,
      ),
    );
  }
}

class _TaskFormDialog extends StatefulWidget {
  final WidgetRef ref;
  final List<Category> categories;
  final Task? existingTask;

  const _TaskFormDialog({
    required this.ref,
    required this.categories,
    this.existingTask,
  });

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final TextEditingController titleController;
  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late List<Category> availableCategories;
  String? selectedCategoryId;

  bool get isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existingTask?.title ?? '',
    );
    selectedDate = widget.existingTask?.dueDate ?? DateTime.now();
    selectedTime = widget.existingTask != null
        ? TimeOfDay.fromDateTime(widget.existingTask!.dueDate)
        : TimeOfDay.now();
    // Dropdown kategori id'si üzerinden çalışıyor (FK), gösterimde
    // Category.name kullanılıyor.
    availableCategories = List.from(widget.categories);
    selectedCategoryId =
        widget.existingTask?.categoryId ??
        (availableCategories.isNotEmpty ? availableCategories.first.id : null);
  }

  @override
  void dispose() {
    // Controller artık bu widget'ın kendi yaşam döngüsüne bağlı — dış bir
    // Future'a (showDialog().then(...)) bağlı DEĞİL. Framework, bu dispose()
    // çağrısını yalnızca widget gerçekten ağaçtan sökülürken tetikler, bu
    // yüzden hâlâ bir rebuild bekleyen bir TextField'ın altından controller'ı
    // çekme riski yok.
    titleController.dispose();
    super.dispose();
  }

  // Not (düzeltme, 28 Temmuz 2026): Bu, önceden kendi TextEditingController'ını
  // tutup dispose()'unu bir try/finally ile "diyalog kapandıktan hemen sonra"
  // çağırıyordu. Ama finally bloğu, addCategory() await'i VE ardından gelen
  // setState() tamamlanana kadar bekliyordu — yani controller aslında
  // diyalog kapandıktan bir süre sonra, dış bir async zincirin bitişine bağlı
  // olarak disposed oluyordu. Bu tam olarak category_management_screen.dart
  // ve önceki görev formu düzeltmesinde gördüğümüz aynı yarış durumu ailesi.
  // Artık ortak CategoryNameDialog kullanılıyor (controller'ı kendi
  // initState/dispose'una bağlı) — bkz. category_name_dialog.dart.
  Future<void> _showAddCategoryDialog() async {
    final createdCategory = await showDialog<Category>(
      context: context,
      builder: (context) => const CategoryNameDialog(
        title: 'Yeni Kategori',
        confirmLabel: 'Ekle',
      ),
    );

    if (createdCategory != null && mounted) {
      setState(() {
        if (!availableCategories.any((c) => c.id == createdCategory.id)) {
          availableCategories.add(createdCategory);
        }
        selectedCategoryId = createdCategory.id;
      });
    }
  }

  void _handleSubmit() {
    // ignore: avoid_print
    print(
      isEditing
          ? '### GUNCELLE BUTONUNA BASILDI ###'
          : '### EKLE BUTONUNA BASILDI ###',
    );

    if (titleController.text.trim().isEmpty) {
      // ignore: avoid_print
      print('### BASLIK BOS, ISLEM DURDU ###');
      return;
    }

    if (selectedCategoryId == null) {
      // ignore: avoid_print
      print('### KATEGORI SECILMEDI, ISLEM DURDU ###');
      return;
    }

    final combinedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // ignore: avoid_print
    print(
      '### GOREV ${isEditing ? "GUNCELLENIYOR" : "OLUSTURULUYOR"}: '
      'dueDate=$combinedDateTime ###',
    );

    final notifier = widget.ref.read(taskListProvider.notifier);
    final existingTask = widget.existingTask;

    if (isEditing && existingTask != null) {
      // Düzenlemede sadece diyalogda gösterilen alanlar
      // (başlık/tarih/saat/kategori) değişiyor. Diyalogda düzenlenmeyen
      // alanları (description, repeatType, isCompleted, createdAt) mevcut
      // görevden aynen koruyoruz — aksi halde örneğin tamamlanmış bir
      // görevi düzenlemek onu yanlışlıkla "tamamlanmadı" durumuna geri
      // döndürebilirdi.
      final updatedTask = Task(
        id: existingTask.id,
        title: titleController.text.trim(),
        description: existingTask.description,
        dueDate: combinedDateTime,
        isCompleted: existingTask.isCompleted,
        repeatType: existingTask.repeatType,
        categoryId: selectedCategoryId!,
        createdAt: existingTask.createdAt,
      );

      notifier
          .updateTask(updatedTask)
          .then((_) {
            // ignore: avoid_print
            print('### updateTask BASARIYLA TAMAMLANDI ###');
          })
          .catchError((e, stack) {
            // ignore: avoid_print
            print('### updateTask HATA VERDI: $e ###');
            // ignore: avoid_print
            print(stack);
          });
    } else {
      final task = Task(
        id: const Uuid().v4(),
        title: titleController.text.trim(),
        dueDate: combinedDateTime,
        categoryId: selectedCategoryId!,
      );

      notifier
          .addTask(task)
          .then((_) {
            // ignore: avoid_print
            print('### addTask BASARIYLA TAMAMLANDI ###');
          })
          .catchError((e, stack) {
            // ignore: avoid_print
            print('### addTask HATA VERDI: $e ###');
            // ignore: avoid_print
            print(stack);
          });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(isEditing ? 'Görevi Düzenle' : 'Yeni Görev'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Başlık'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tarih: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saat: ${selectedTime.hour.toString().padLeft(2, '0')}:'
                  '${selectedTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategoryId,
                  hint: const Text('Kategori seç'),
                  items: availableCategories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategoryId = value);
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Yeni kategori ekle',
                onPressed: _showAddCategoryDialog,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          child: Text(isEditing ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
}
