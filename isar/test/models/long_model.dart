import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class LongModel with IsarObject {
  @Index()
  int? field = 0;

  LongModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as LongModel).field == field;
  }
}
