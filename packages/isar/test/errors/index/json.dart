// json properties cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @index
  dynamic val1;

  String? val2;
}
