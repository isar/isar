import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

part 'string_model_cis.g.dart';

@Collection()
class StringModelCIS {
  @Id()
  int? id;

  @Index(type: IndexType.value, caseSensitive: false)
  String? field = '';

  @Index(type: IndexType.hash, caseSensitive: false)
  String? hashField = '';

  @Index(type: IndexType.value, caseSensitive: false)
  List<String>? list;

  @Index(type: IndexType.hash, caseSensitive: false)
  List<String>? hashList;

  @Index(type: IndexType.hashElements, caseSensitive: false)
  List<String>? hashElementList;

  @override
  String toString() {
    return '{field: $field, hashField: $hashField, list: $list, hashList: $hashList, hashElementList: $hashElementList}';
  }

  StringModelCIS();

  StringModelCIS.init(String? value)
      : field = value,
        hashField = value;

  @override
  bool operator ==(other) {
    if (other is StringModelCIS) {
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
