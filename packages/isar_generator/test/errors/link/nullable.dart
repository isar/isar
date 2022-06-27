// must not be nullable

import 'package:isar/isar.dart';

@Collection()
class Model {
  int? id;

  IsarLink<Model2>? link;
}

@Collection()
class Model2 {
  int? id;
}
