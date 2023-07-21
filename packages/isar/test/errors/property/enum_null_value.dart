// null values are not supported

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum prop;
}

enum MyEnum {
  optionA;

  @enumValue
  final String? value = null;
}
