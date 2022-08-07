// links type must not be nullable

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  final IsarLink<Model2?> link = IsarLink();
}

@Collection()
class Model2 {
  Id? id;
}
