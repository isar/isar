// unsupported type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum prop;
}

enum MyEnum with IsarEnum<String?> {
  optionA;

  @override
  String? get value => null;
}
