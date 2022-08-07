// only string lists may have hashed elements

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(type: IndexType.hashElements)
  List<int>? list;
}
