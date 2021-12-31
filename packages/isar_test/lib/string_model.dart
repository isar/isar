import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

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
          listEquals(list, other.list) &&
          listEquals(hashList, other.hashList) &&
          listEquals(hashElementList, other.hashElementList);
    }
    return false;
  }
}
