// target of backlink is not a link

import 'package:isar/isar.dart';

@collection
class Model1 {
  Id? id;

  @Backlink(to: 'str')
  final IsarLink<Model2> link = IsarLink();
}

@collection
class Model2 {
  Id? id;

  String? str;
}
