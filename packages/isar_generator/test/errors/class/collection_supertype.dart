// supertype annotated with @collection

import 'package:isar/isar.dart';

@Collection()
class Supertype {
  Id? id;
}

class Subtype implements Supertype {
  @override
  Id? id;
}

@Collection()
class Model implements Subtype {
  @override
  Id? id;
}
