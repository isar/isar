// supertype annotated with @collection

import 'package:isar/isar.dart';

@collection
class Supertype {
  Id? id;
}

class Subtype implements Supertype {
  @override
  Id? id;
}

@collection
class Model implements Subtype {
  @override
  Id? id;
}
