// composite index contains duplicate properties

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('str1')], type: IndexType.value)
  String? str1;

  String? str2;
}
