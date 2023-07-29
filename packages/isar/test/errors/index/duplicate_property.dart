// composite index contains duplicate properties

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @Index(composite: ['str2', 'str1'])
  String? str1;

  String? str2;
}
