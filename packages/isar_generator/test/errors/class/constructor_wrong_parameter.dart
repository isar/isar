// constructor parameter type does not match property type

import 'package:isar/isar.dart';

@collection
class Model {
  // ignore: avoid_unused_constructor_parameters
  Model(int prop1);

  Id? id;

  String prop1 = '5';
}
