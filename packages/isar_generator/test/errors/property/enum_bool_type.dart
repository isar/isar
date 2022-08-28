// enums do not support bool values

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum field;
}

enum MyEnum {
  optionA;

  final bool value = true;
}
