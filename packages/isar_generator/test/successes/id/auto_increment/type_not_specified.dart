import 'package:isar/isar.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(
  "idName: r'id'",
  contains: true,
)
@Collection()
class Mutable {
  // ignore: type_annotate_public_apis
  var id = Isar.autoIncrement;
}

@ShouldGenerate(
  "idName: r'id'",
  contains: true,
)
@Collection()
class Immutable {
  final id = Isar.autoIncrement;
}
