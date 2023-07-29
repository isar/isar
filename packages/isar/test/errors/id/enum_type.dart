// only int and string properties can be used as id

import 'package:isar/isar.dart';

@collection
class Test {
  late TestEnum id;
}

enum TestEnum { a, b, c }
