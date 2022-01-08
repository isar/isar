import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';

part 'double_model.g.dart';

@Collection()
class DoubleModel {
  @Id()
  int? id;

  @Index()
  double? field = 0;

  @Index(type: IndexType.value)
  List<double?>? list;

  DoubleModel();

  @override
  String toString() {
    return '{id: $id, field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as DoubleModel;
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
