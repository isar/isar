import 'package:isar/isar.dart';

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

  @Index(type: IndexType.hash)
  @Size32()
  List<double>? hashList;

  FloatModel();

  @override
  String toString() {
    return '{field: $field, list: $list, hashList: $hashList}';
  }

  @override
  bool operator ==(other) {
    final otherModel = other as FloatModel;
    if ((other.field == null) != (field == null)) {
      return false;
    } else if (field != null && (otherModel.field! - field!).abs() > 0.001) {
      return false;
    } else if (other.list?.length != list?.length) {
      return false;
    } else if (other.hashList?.length != hashList?.length) {
      return false;
    }

    if (list != null) {
      for (var i = 0; i < list!.length; i++) {
        if ((otherModel.list![i] - list![i]).abs() > 0.001) {
          return false;
        }
      }
    }

    if (hashList != null) {
      for (var i = 0; i < hashList!.length; i++) {
        if ((otherModel.hashList![i] - hashList![i]).abs() > 0.001) {
          return false;
        }
      }
    }

    return true;
  }
}
