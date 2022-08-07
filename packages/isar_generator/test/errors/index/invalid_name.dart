// names must not be blank or start with "_"

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(name: '_index')
  String? str;
}
