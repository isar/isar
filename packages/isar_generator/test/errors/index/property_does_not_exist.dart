// property does not exist

import 'package:isar/isar.dart';

@Collection()
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('myProp')])
  String? str;
}
