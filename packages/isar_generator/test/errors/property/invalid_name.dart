// names must not be blank or start with "_"

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Name('_prop')
  String? prop;
}
