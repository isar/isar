import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

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
          listEquals(list, other.list) &&
          listEquals(hashList, other.hashList) &&
          listEquals(hashElementList, other.hashElementList);
    }
    return false;
  }
}
