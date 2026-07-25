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

/// Her tab başlık+ikon+ekranı TEK nesnede taşıyor (bkz.
/// settings_menu_screen.dart'taki aynı prensip). Önceki halde ekranlar
/// (_screens) ve BottomNavigationBarItem'lar (ikon+etiket) iki AYRI
/// listede tutuluyor, index üzerinden eşleşiyordu — biri güncellenip
/// diğeri unutulursa sessizce yanlış eşleşme oluşabilirdi. Tek liste bu
/// riski ortadan kaldırıyor.
class _HomeTab {
  final String label;
  final IconData icon;
  final Widget screen;

  const _HomeTab({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  static const _tabs = [
    _HomeTab(
      label: 'Görevler',
      icon: Icons.checklist,
      screen: TaskListScreen(),
    ),
    _HomeTab(
      label: 'Takvim',
      icon: Icons.calendar_month,
      screen: CalendarScreen(),
    ),
    _HomeTab(label: 'Sayaç', icon: Icons.timer, screen: TimerScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex].screen,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
