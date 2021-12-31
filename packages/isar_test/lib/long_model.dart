import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

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
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}
