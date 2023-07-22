// bytes must not be nullable

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  late byte? prop;
}
