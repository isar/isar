import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class IntIndex with IsarObjectMixin {
  @Index()
  int field = 0;

  IntIndex();

  @override
  bool operator ==(other) {
    return (other as IntIndex).field == field;
  }
}
