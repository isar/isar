import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class BoolModel with IsarObject {
  @Index()
  bool? field = false;

  BoolModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as BoolModel).field == field;
  }
}
