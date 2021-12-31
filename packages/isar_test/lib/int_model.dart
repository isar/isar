import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

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
    return '{id: $id, field: $field, list: $list}';
  }

  @override
  bool operator ==(other) {
    return (other as IntModel).field == field &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}
