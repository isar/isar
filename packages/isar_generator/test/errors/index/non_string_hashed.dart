// only strings and lists may be hashed

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Index(type: IndexType.hash)
  int? val;
}
