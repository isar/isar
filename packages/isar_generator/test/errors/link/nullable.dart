// must not be nullable

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  IsarLink<Model2>? link;
}

@collection
class Model2 {
  Id? id;
}
