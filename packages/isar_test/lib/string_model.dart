import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

part 'string_model.g.dart';

@Collection()
class StringModel {
  @Id()
  int? id;

  @Index(type: IndexType.value)
  String? field = '';

  @Index(type: IndexType.hash)
  String? hashField = '';

  @Index(type: IndexType.value)
  List<String>? list;

  @Index(type: IndexType.hash)
  List<String>? hashList;

  @Index(type: IndexType.hashElements)
  List<String>? hashElementList;

  @override
  String toString() {
    return '{field: $field, hashField: $hashField, list: $list, hashList: $hashList, hashElementList: $hashElementList}';
  }

  StringModel();

  StringModel.init(String? value)
      : field = value,
        hashField = value;

  @override
  bool operator ==(other) {
    if (other is StringModel) {
      return field == other.field &&
          hashField == other.hashField &&
          list?.length == other.list?.length &&
          (list?.contentEquals(other.list!) ?? true) &&
          hashList?.length == other.hashList?.length &&
          (hashList?.contentEquals(other.hashList!) ?? true) &&
          hashElementList?.length == other.hashElementList?.length &&
          (hashElementList?.contentEquals(other.hashElementList!) ?? true);
    }
    return false;
  }
}
