// enums do not support object values

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum prop;
}

enum MyEnum with IsarEnum<EmbeddedModel> {
  optionA;

  @override
  EmbeddedModel get value => EmbeddedModel();
}

@embedded
class EmbeddedModel {}
