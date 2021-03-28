import 'package:isar/isar.dart';

import '../isar.g.dart';

@Collection()
class DoubleModel {
  @Id()
  int? id;

  @Index()
  double? field = 0;

  DoubleModel();

  @override
  String toString() {
    return '{field: $field}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as DoubleModel;
    if (otherModel.field == null || field == null) {
      return otherModel.field == null && field == null;
    } else {
      return (otherModel.field! - field!).abs() < 0.001;
    }
  }
}
