// constructor parameter does not match a property

import 'package:isar/isar.dart';

@collection
class Model {
  // ignore: avoid_unused_constructor_parameters
  Model(this.prop1, String somethingElse);

  Id? id;

  final String prop1;
}
