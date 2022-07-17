import 'package:isar/isar.dart';

@Collection()
class Mutable {
  // ignore: type_annotate_public_apis
  var id = Isar.minId;
}

@Collection()
class Immutable {
  final id = Isar.minId;
}
