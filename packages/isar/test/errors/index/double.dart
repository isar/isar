// double properties cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @index
  double? val1;

  String? val2;
}
