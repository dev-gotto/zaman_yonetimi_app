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

  @HiveField(6)
  String category;

  @HiveField(7)
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    this.isCompleted = false,
    this.repeatType = 0,
    this.category = 'Genel',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RepeatType get repeat => RepeatType.values[repeatType];
  set repeat(RepeatType value) => repeatType = value.index;
}