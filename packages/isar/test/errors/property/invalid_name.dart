// names must not be blank or start with "_"

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @Name('_prop')
  String? prop;
}
