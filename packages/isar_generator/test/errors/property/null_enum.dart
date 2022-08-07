// bytes must not be nullable

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  late byte? prop;
}

enum MyEnum with IsarEnum<String?> {
  optionA;

  @override
  String? get isarValue => null;
}
