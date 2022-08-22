// unsupported type

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum prop;
}

enum MyEnum with IsarEnum<List<String>> {
  optionA;

  @override
  List<String> get value => [];
}
