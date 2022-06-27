// must not be late

import 'package:isar/isar.dart';

@Collection()
class Model {
  int? id;

  late IsarLink<Model2> link;
}

@Collection()
class Model2 {
  int? id;
}
