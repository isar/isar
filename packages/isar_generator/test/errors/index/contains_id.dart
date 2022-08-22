// ids cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  Id? id;

  @Index(composite: [CompositeIndex('id')])
  String? str;
}
