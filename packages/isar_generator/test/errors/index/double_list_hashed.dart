// list<double> may must not be hashed

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(type: IndexType.hash)
  List<double>? list;
}
