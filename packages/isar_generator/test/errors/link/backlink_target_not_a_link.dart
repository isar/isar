// target of backlink is not a link

import 'package:isar/isar.dart';

@Collection()
class Model1 {
  Id? id;

  @Backlink(to: 'str')
  final IsarLink<Model2> link = IsarLink();
}

@Collection()
class Model2 {
  Id? id;

  String? str;
}
