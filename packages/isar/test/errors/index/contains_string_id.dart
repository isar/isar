// ids cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late String id;

  @Index(composite: ['id'])
  int? value;
}
