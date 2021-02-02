import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class IntModel {
  @ObjectId()
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
