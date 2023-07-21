// unsupported enum property type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum prop;
}

enum MyEnum {
  optionA;

  @enumValue
  final value = EmbeddedModel();
}

@embedded
class EmbeddedModel {}
