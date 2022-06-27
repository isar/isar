// Two or more properties annotated with @Id()

import 'package:isar/isar.dart';

@Collection()
class Test {
  @Id()
  int? id1;

  @Id()
  int? id2;
}
