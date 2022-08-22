// enums do not support floating point values

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late MyEnum field;
}

enum MyEnum with IsarEnum<double> {
  optionA;

  @override
  double get value => 5.5;
}
