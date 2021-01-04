import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class BoolIndex with IsarObjectMixin {
  @Index()
  bool? field = false;

  BoolIndex();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as BoolIndex).field == field;
  }
}
