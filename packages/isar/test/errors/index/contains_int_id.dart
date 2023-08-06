// ids cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @Index(composite: ['id'])
  int? str;
}
