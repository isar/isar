import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class LongIndex with IsarObject {
  @Index()
  int? field = 0;

  LongIndex();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as LongIndex).field == field;
  }
}
