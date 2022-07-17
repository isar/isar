import 'package:isar/isar.dart';

@Collection()
class Test {
  @Name('id')
  Id testId = Isar.autoIncrement;
}
