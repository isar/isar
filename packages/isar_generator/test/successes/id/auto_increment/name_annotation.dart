import 'package:isar/isar.dart';
import 'package:source_gen_test/annotations.dart';

@ShouldGenerate(
  "idName: r'id'",
  contains: true,
)
@Collection()
class Test {
  @Name('id')
  Id testId = Isar.autoIncrement;
}
