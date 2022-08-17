// bytes must not be nullable

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  late List<byte?> prop;
}
