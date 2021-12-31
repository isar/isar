import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

part 'bool_model.g.dart';

@Collection()
class BoolModel {
  @Id()
  int? id;

  @Index()
  bool? field = false;

  @Index(type: IndexType.value)
  List<bool?>? list;

  @Index(type: IndexType.hash)
  List<bool?>? hashList;

  BoolModel();

  @override
  String toString() {
    return '{field: $field, list: $list, hashList: $hashList}';
  }

  @override
  bool operator ==(other) {
    return (other as BoolModel).field == field &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}
