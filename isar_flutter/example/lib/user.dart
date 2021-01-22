import 'dart:typed_data';

import 'test_converter.dart';
import 'package:isar/isar.dart';

@Collection()
class User with IsarObject {
  // @Index(composite: ['age'], unique: false)
  late String? name;

  @Index(unique: false)
  @TestConverter2()
  late String age;

  late List<int> ages;

  late Uint8List? someBytes;

  @override
  String toString() {
    return "name: $name  age: $age";
  }
}
