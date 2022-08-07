// target of backlink does not exist

import 'package:isar/isar.dart';

@Collection()
class Model1 {
  Id? id;

  @Backlink(to: 'abc')
  final IsarLink<Model2> link = IsarLink();
}

@Collection()
class Model2 {
  Id? id;
}
