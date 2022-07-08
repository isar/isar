// must not be late

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  late IsarLink<Model2> link;
}

@Collection()
class Model2 {
  Id? id;
}
