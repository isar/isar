import 'package:isar/isar.dart';

void main() {
  if (Isar.version.isEmpty) {
    throw StateError('Missing Isar version');
  }
  Isar.open(const [], name: 'compile-smoke');
}
