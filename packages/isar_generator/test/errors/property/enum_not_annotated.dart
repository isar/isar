// enum property must be annotated with @enumerated

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum? prop;
}

enum MyEnum {
  a;
}
