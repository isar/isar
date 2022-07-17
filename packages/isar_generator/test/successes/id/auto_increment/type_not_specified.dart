import 'package:isar/isar.dart';

@Collection()
class Mutable {
  // ignore: type_annotate_public_apis
  var id = Isar.autoIncrement;
}

@Collection()
class Immutable {
  final id = Isar.autoIncrement;
}
