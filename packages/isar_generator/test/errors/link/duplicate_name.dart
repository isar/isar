// same name

import 'package:isar/isar.dart';

@Collection()
class Model {
  int? id;

  final IsarLink<Model2> prop1 = IsarLink();

  @Name('prop1')
  final IsarLinks<Model2> prop2 = IsarLinks();
}

@Collection()
class Model2 {
  int? id;
}
