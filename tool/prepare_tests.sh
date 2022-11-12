cd packages/isar_test

flutter pub get
dart tool/generate_long_double_test.dart
dart tool/generate_all_tests.dart
flutter pub run build_runner build