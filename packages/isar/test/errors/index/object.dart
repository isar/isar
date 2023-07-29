// embedded object properties cannot be indexed

import 'package:isar/isar.dart';

@collection
class Model {
  late int id;

  @Index()
  EmbeddedModel? obj;
}

@embedded
class EmbeddedModel {}
