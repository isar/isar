// unsupported type

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  late MyEnum? prop;
}

enum MyEnum {
  a;
}
