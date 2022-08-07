import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_bool_list_test.g.dart';

@Collection()
class BoolModel {
  BoolModel(this.list) : hashList = list;

  Id? id;

  @Index(type: IndexType.value)
  List<bool?>? list;

  @Index(type: IndexType.hash)
  List<bool?>? hashList;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is BoolModel &&
        other.id == id &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}

void main() {
  group('Bool list filter', () {
    late Isar isar;
    late IsarCollection<BoolModel> col;

    late BoolModel objEmpty;
    late BoolModel obj1;
    late BoolModel obj2;
    late BoolModel obj3;
    late BoolModel objNull;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema]);
      col = isar.boolModels;

      objEmpty = BoolModel([]);
      obj1 = BoolModel([true]);
      obj2 = BoolModel([null, false]);
      obj3 = BoolModel([true, false, true]);
      objNull = BoolModel(null);

      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('.elementEqualTo()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementEqualTo(true).tFindAll(),
        [obj1, obj3],
      );
      await qEqualSet(col.where().listElementEqualTo(null).tFindAll(), [obj2]);

      // filters
      await qEqual(
        col.filter().listElementEqualTo(true).tFindAll(),
        [obj1, obj3],
      );
      await qEqual(col.filter().listElementEqualTo(null).tFindAll(), [obj2]);
    });

    isarTest('.elementNotEqualTo()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementNotEqualTo(true).tFindAll(),
        [obj2, obj3],
      );
      await qEqualSet(
        col.where().listElementNotEqualTo(null).tFindAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('.elementIsNull()', () async {
      // where clauses
      await qEqualSet(col.where().listElementIsNull().tFindAll(), [obj2]);

      // filters
      await qEqual(
        col.where().filter().listElementIsNull().tFindAll(),
        [obj2],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      // where clauses
      await qEqualSet(
        col.where().listElementIsNotNull().tFindAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('.equalTo()', () async {
      // where clauses
      await qEqualSet(col.where().hashListEqualTo(null).tFindAll(), [objNull]);
      await qEqualSet(col.where().hashListEqualTo([]).tFindAll(), [objEmpty]);
      await qEqualSet(
        col.where().hashListEqualTo([null, false]).tFindAll(),
        [obj2],
      );
    });

    isarTest('.notEqualTo()', () async {
      // where clauses
      await qEqualSet(
        col.where().hashListNotEqualTo([]).tFindAll(),
        [objNull, obj1, obj2, obj3],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([true, false, true]).tFindAll(),
        [objEmpty, obj1, obj2, objNull],
      );
    });

    isarTest('.isNull()', () async {
      // where clauses
      await qEqualSet(col.where().hashListIsNull().tFindAll(), [objNull]);

      // filters
      await qEqual(
        col.where().filter().hashListIsNull().tFindAll(),
        [objNull],
      );
    });

    isarTest('.isNotNull()', () async {
      // where clauses
      await qEqualSet(
        col.where().hashListIsNotNull().tFindAll(),
        [objEmpty, obj1, obj2, obj3],
      );
    });
  });
}
