@echo off
REM Bu dosyayi zaman_yonetimi_app klasorunun icinde calistir
REM (icinde lib, android, pubspec.yaml vs. olan klasor)

echo Klasor yapisi olusturuluyor...

mkdir lib\core\models
mkdir lib\core\repositories
mkdir lib\core\providers
mkdir lib\features\tasks

REM Bos dosyalari olustur (icini sonra dolduracaksin)
type nul > lib\core\models\task.dart
type nul > lib\core\repositories\task_repository.dart
type nul > lib\core\repositories\hive_task_repository.dart
type nul > lib\core\providers\repository_provider.dart
type nul > lib\core\providers\task_provider.dart
type nul > lib\features\tasks\task_list_screen.dart

echo.
echo Tamamlandi! Olusturulan yapi:
echo.
tree lib /F

echo.
echo Simdi her dosyanin icine ilgili kodu yapistir.
echo main.dart dosyasi zaten lib klasorunun icinde mevcut, onu da guncellemeyi unutma.
pause