// unsupported type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum? prop;
}

enum MyEnum {
  a;
}
