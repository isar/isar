// property does not exist

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @Index(composite: ['myProp'])
  int? value;
}
