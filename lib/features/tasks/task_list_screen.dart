import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/task.dart';
import '../../core/models/category.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/category_provider.dart';
import '../timer/timer_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final categoriesAsync = ref.watch(categoryListProvider);
    final categoryById = ref.watch(categoryByIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Görevlerim')),
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
                child: CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: task.isCompleted,
                  onChanged: (_) {
                    ref.read(taskListProvider.notifier).toggleComplete(task.id);
                  },
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
                  subtitle: Text(
                    '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year} '
                    '${task.dueDate.hour.toString().padLeft(2, '0')}:'
                    '${task.dueDate.minute.toString().padLeft(2, '0')} • '
                    '${categoryById[task.categoryId]?.name ?? "Bilinmeyen kategori"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondary: IconButton(
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(
          context,
          ref,
          categoriesAsync.value ?? const [],
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    final titleController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    List<Category> availableCategories = List.from(categories);
    // Dropdown artık kategori id'si üzerinden çalışıyor (FK), gösterimde
    // Category.name kullanılıyor.
    String? selectedCategoryId = availableCategories.isNotEmpty
        ? availableCategories.first.id
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: const Text('Yeni Görev'),
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
                    onPressed: () async {
                      final newCategoryController = TextEditingController();
                      final newCategory = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Yeni Kategori'),
                          content: TextField(
                            controller: newCategoryController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Kategori adı',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('İptal'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(
                                context,
                                newCategoryController.text.trim(),
                              ),
                              child: const Text('Ekle'),
                            ),
                          ],
                        ),
                      );

                      if (newCategory != null && newCategory.isNotEmpty) {
                        final createdCategory = await ref
                            .read(categoryListProvider.notifier)
                            .addCategory(newCategory);
                        setState(() {
                          if (!availableCategories.any(
                            (c) => c.id == createdCategory.id,
                          )) {
                            availableCategories.add(createdCategory);
                          }
                          selectedCategoryId = createdCategory.id;
                        });
                      }
                    },
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
              onPressed: () {
                // ignore: avoid_print
                print('### EKLE BUTONUNA BASILDI ###');

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
                print('### GOREV OLUSTURULUYOR: dueDate=$combinedDateTime ###');

                final task = Task(
                  id: const Uuid().v4(),
                  title: titleController.text.trim(),
                  dueDate: combinedDateTime,
                  categoryId: selectedCategoryId!,
                );

                ref
                    .read(taskListProvider.notifier)
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

                Navigator.pop(context);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
