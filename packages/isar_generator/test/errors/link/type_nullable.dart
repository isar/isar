// links type must not be nullable

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  final IsarLink<Model2?> link = IsarLink();
}

@collection
class Model2 {
  Id? id;
}
