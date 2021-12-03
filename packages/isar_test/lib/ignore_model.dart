import 'package:isar/isar.dart';

@Collection()
class IgnoreModel {
  int? id;

  String? name;

  @Ignore()
  String? ignoredName;

  @Ignore()
  final int ignoredFinal = 5;

  @Ignore()
  String get ignoredGetter => 'hello';
}
