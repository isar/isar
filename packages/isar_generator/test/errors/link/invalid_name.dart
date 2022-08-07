// names must not be blank or start with

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Name('_link')
  final IsarLink<Model2> link = IsarLink();
}

@Collection()
class Model2 {
  Id? id;
}
