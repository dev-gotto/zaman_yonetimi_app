import 'package:hive/hive.dart';

part 'task.g.dart';

enum RepeatType { none, daily, weekly, monthly }

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime dueDate;

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  int repeatType; // RepeatType index olarak saklanır

  // Kategori-FK migration: önceden düz kategori adı (String) tutuluyordu.
  // Artık Category modelinin id'sine referans veriyor (FK). Alan numarası
  // (6) kasıtlı olarak DEĞİŞTİRİLMEDİ — Hive alanları isme değil index'e
  // göre okur/yazar, bu sayede eski binary veriyle geriye dönük uyumluluk
  // korunuyor. Var olan görevlerdeki eski kategori adları, uygulama
  // başlangıcında CategoryFkMigration tarafından gerçek id'lere çevriliyor.
  @HiveField(6)
  String categoryId;

  @HiveField(7)
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.repeatType = 0,
    required this.categoryId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RepeatType get repeat => RepeatType.values[repeatType];
  set repeat(RepeatType value) => repeatType = value.index;
}