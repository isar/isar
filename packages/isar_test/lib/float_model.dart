import 'package:isar/isar.dart';

import 'common.dart';

part 'float_model.g.dart';

@Collection()
class FloatModel {
  @Id()
  int? id;

  @Index()
  double? field = 0;

  @Index(type: IndexType.value)
  @Size32()
  List<double>? list;

  FloatModel();

  @override
  String toString() {
    return '{field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as FloatModel;
    if ((other.field == null) != (field == null)) {
      return false;
    } else if (field != null && (otherModel.field! - field!).abs() > 0.001) {
      return false;
    } else if (!doubleListEquals(list, other.list)) {
      return false;
    }

    return true;
  }
}
