import 'package:isar/isar.dart';

void main() {
  if (Isar.version.isEmpty) {
    throw StateError('Missing Isar version');
  }
}
