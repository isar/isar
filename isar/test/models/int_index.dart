import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class IntIndex with IsarObject {
  @Index()
  @Size32()
  int? field = 0;

  IntIndex();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as IntIndex).field == field;
  }
}
