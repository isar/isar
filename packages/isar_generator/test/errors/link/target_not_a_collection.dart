// link target is not annotated with @collection()

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  final IsarLink<int> link = IsarLink();
}
