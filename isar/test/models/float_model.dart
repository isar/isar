import 'package:isar/isar.dart';

import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class FloatModel {
  @Id()
  int? id;

  @Index()
  @Size32()
  double? field = 0;

  FloatModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as FloatModel;
    if (otherModel.field == null || field == null) {
      return otherModel.field == null && field == null;
    } else {
      return (otherModel.field! - field!).abs() < 0.001;
    }
  }
}
