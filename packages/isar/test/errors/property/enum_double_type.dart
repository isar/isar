// unsupported enum property type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum field;
}

enum MyEnum {
  optionA;

  @enumValue
  final double value = 5.5;
}
