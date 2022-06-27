// Only int ids are allowed

import 'package:isar/isar.dart';

@Collection()
class Test {
  @Id()
  @Size32()
  int? id;
}
