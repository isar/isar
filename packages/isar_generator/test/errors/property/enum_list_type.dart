// unsupported enum property type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum prop;
}

enum MyEnum {
  optionA;

  final List<String> value = [];
}
