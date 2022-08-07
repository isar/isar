// target of backlink is also a backlink

import 'package:isar/isar.dart';

@Collection()
class Model1 {
  Id? id;

  @Backlink(to: 'link')
  final IsarLink<Model2> link = IsarLink();
}

@Collection()
class Model2 {
  Id? id;

  @Backlink(to: 'link')
  final IsarLink<Model1> link = IsarLink();
}
