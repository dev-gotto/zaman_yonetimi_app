// GENERATED CODE - DO NOT MODIFY BY HAND
//
// NOT: build_runner bu geliştirme ortamında çalıştırılamadığı için bu adapter
// hive_generator'ın ürettiği standart pattern'e (bkz. task.g.dart) birebir
// uyularak elle yazıldı. Projeyi indirdikten sonra bir fırsatta:
//   flutter pub run build_runner build --delete-conflicting-outputs
// komutunu çalıştırıp bu dosyanın yeniden üretilmesi, elle yazılan içeriğin
// gerçek codegen çıktısıyla eşleştiğini doğrulaman için önerilir.

part of 'category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(id: fields[0] as String, name: fields[1] as String);
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
