// same name

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  final IsarLink<Model2> prop1 = IsarLink();

  @Name('prop1')
  final IsarLinks<Model2> prop2 = IsarLinks();
}

@Collection()
class Model2 {
  Id? id;
}
