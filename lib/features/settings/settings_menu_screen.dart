import 'package:flutter/material.dart';
import '../categories/category_management_screen.dart';
import '../stats/stats_screen.dart';

/// Menü öğeleri "çocuk nesne" (data record) olarak tanımlanıyor: her satır
/// başlık+ikon+hedef ekranı TEK bir nesnede taşıyor. Yeni bir ayarlar/araç
/// ekranı eklemek bu listeye tek satır eklemek demek — build() metoduna
/// dokunmaya gerek yok, sıra/ikon/başlık birbirinden kopması riski olmuyor.
/// Aynı prensip main.dart'taki _HomeTab için de uygulandı.
class _SettingsMenuItem {
  final String title;
  final IconData icon;
  final WidgetBuilder screenBuilder;

  const _SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.screenBuilder,
  });
}

final List<_SettingsMenuItem> _settingsMenuItems = [
  _SettingsMenuItem(
    title: 'Kategorileri Yönet',
    icon: Icons.category_outlined,
    screenBuilder: (_) => const CategoryManagementScreen(),
  ),
  _SettingsMenuItem(
    title: 'İstatistikler',
    icon: Icons.bar_chart_outlined,
    screenBuilder: (_) => const StatsScreen(),
  ),
];

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView.builder(
        itemCount: _settingsMenuItems.length,
        itemBuilder: (context, index) {
          final item = _settingsMenuItems[index];
          return ListTile(
            leading: Icon(item.icon),
            title: Text(item.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: item.screenBuilder),
              );
            },
          );
        },
      ),
    );
  }
}
