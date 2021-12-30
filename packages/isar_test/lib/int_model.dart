import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

part 'int_model.g.dart';

@Collection()
class IntModel {
  @Id()
  int? id;

  @Index()
  @Size32()
  int? field = 0;

  @Index(type: IndexType.value)
  @Size32()
  List<int>? list;

  @Index(type: IndexType.hash)
  @Size32()
  List<int>? hashList;

  IntModel();

  @override
  String toString() {
    return '{field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    return (other as IntModel).field == field &&
        list?.length == other.list?.length &&
        (list?.contentEquals(other.list!) ?? true) &&
        hashList?.length == other.hashList?.length &&
        (hashList?.contentEquals(other.hashList!) ?? true);
  }
}
