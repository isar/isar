// enums do not support object values

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Enumerated(EnumType.value, 'value')
  late MyEnum prop;
}

enum MyEnum {
  optionA;

  final value = EmbeddedModel();
}

@embedded
class EmbeddedModel {}
