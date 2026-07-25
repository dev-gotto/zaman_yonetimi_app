import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers/repository_provider.dart';
import 'core/migration/category_fk_migration.dart';
import 'features/tasks/task_list_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/timer/timer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Zaman Yönetimi',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: const _AppInitializer(),
    );
  }
}

class _AppInitializer extends ConsumerWidget {
  const _AppInitializer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(taskRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);

    return FutureBuilder(
      // Kategori-FK migration, kategori/görev repository'leri init
      // edilmeden ÖNCE tamamlanmalı — HiveCategoryRepository.init() box'ın
      // boş olup olmadığına bakarak varsayılan kategori seed'lemesi
      // yapıyor, migration'ın veriyi taşımış olması bu kararı etkiliyor.
      future: CategoryFkMigration.runIfNeeded().then(
        (_) => Future.wait([
          repo.init(),
          categoryRepo.init(),
          notificationService.init(),
        ]),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const _HomeShell();
      },
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  static const _screens = [TaskListScreen(), CalendarScreen(), TimerScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: 'Görevler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Takvim',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Sayaç'),
        ],
      ),
    );
  }
}
