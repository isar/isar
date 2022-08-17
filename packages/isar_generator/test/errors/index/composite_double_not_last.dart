// only the last property of a composite index may be a double value

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('val2')])
  double? val1;

  String? val2;
}
