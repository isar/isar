import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

part 'long_model.g.dart';

@Collection()
class LongModel {
  @Id()
  int? id;

  @Index()
  int? field = 0;

  @Index(type: IndexType.value)
  List<int>? list;

  @Index(type: IndexType.hash)
  List<int>? hashList;

  LongModel();

  @override
  String toString() {
    return '{field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    return (other as LongModel).field == field &&
        list?.length == other.list?.length &&
        (list?.contentEquals(other.list!) ?? true) &&
        hashList?.length == other.hashList?.length &&
        (hashList?.contentEquals(other.hashList!) ?? true);
  }
}
