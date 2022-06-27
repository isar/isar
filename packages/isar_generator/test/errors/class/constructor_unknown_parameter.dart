// constructor parameter does not match a property

import 'package:isar/isar.dart';

@Collection()
class Model {
  // ignore: avoid_unused_constructor_parameters
  Model(this.prop1, String somethingElse);

  int? id;

  final String prop1;
}
