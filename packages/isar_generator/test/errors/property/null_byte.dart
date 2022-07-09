// Bytes cannot be nullable

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  late byte? prop;
}
