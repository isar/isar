import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

part 'bool_model.g.dart';

@Collection()
class BoolModel {
  @Id()
  int? id;

  @Index()
  bool? field = false;

  @Index()
  List<bool>? list;

  BoolModel();

  @override
  String toString() {
    return '{field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    return (other as BoolModel).field == field &&
        list?.length == other.list?.length &&
        (list?.contentEquals(other.list!) ?? true);
  }
}
