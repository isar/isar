// has duplicate values

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum field;
}

enum MyEnum {
  option1(1),
  option2(2),
  option3(1);

  const MyEnum(this.value);

  @enumValue
  final int value;
}
