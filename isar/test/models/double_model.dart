import '../isar.g.dart';
import 'package:isar_annotation/isar_annotation.dart';

@Collection()
class DoubleModel with IsarObject {
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
