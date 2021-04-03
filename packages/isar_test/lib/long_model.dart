import 'package:isar/isar.dart';

@Collection()
class LongModel {
  @Id()
  int? id;

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
