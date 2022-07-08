// same name

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(name: 'myindex')
  String? prop1;

  @Index(name: 'myindex')
  String? prop2;
}
