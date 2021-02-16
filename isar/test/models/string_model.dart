import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class StringModel {
  @ObjectId()
  int? id;

  @Index()
  String? field = '';

  StringModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    return (other as StringModel).field == field;
  }
}
