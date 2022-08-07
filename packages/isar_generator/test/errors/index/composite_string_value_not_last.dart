// last property of a composite index may be a non-hashed string

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('str2')], type: IndexType.value)
  String? str1;

  String? str2;
}
