// only unique indexes can replace

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(replace: true)
  String? str;
}
