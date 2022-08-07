import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_string_list_test.g.dart';

@Collection()
class StringModel {
  StringModel();

  StringModel.init(this.list)
      : hashList = list,
        hashElementList = list;

  Id? id;

  @Index(type: IndexType.value)
  List<String>? list;

  @Index(type: IndexType.hash)
  List<String>? hashList;

  @Index(type: IndexType.hashElements)
  List<String>? hashElementList;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is StringModel) {
      return listEquals(list, other.list) &&
          listEquals(hashList, other.hashList) &&
          listEquals(hashElementList, other.hashElementList);
    }
    return false;
  }
}

void main() {
  group('String filter', () {
    late Isar isar;
    late IsarCollection<StringModel> col;
  });

  // TODO
}
