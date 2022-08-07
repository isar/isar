// only strings and lists may be hashed

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(type: IndexType.hash)
  int? val;
}
