// list properties cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @index
  List<int>? val1;

  String? val2;
}
