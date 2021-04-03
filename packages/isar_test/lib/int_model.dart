import 'package:isar/isar.dart';

@Collection()
class IntModel {
  @Id()
  int? id;

  @Index()
  @Size32()
  int? field = 0;

  IntModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as IntModel).field == field;
  }
}
