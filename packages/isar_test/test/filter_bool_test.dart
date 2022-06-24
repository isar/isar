import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'filter_bool_test.g.dart';

@Collection()
class BoolModel {
  BoolModel();
  @Id()
  int? id;

  @Index()
  bool? field = false;

  @Index(type: IndexType.value)
  List<bool?>? list;

  @Index(type: IndexType.hash)
  List<bool?>? hashList;

  @override
  String toString() {
    return '{id: $id, field: $field, list: $list, hashList: $hashList}';
  }

  @override
  bool operator ==(Object other) {
    // ignore: test_types_in_equals
    return (other as BoolModel).id == id &&
        other.field == field &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}

void main() {
  group('Bool filter', () {
    late Isar isar;
    late IsarCollection<BoolModel> col;

    late BoolModel objNull;
    late BoolModel objFalse;
    late BoolModel objTrue;
    late BoolModel objFalse2;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema]);
      col = isar.boolModels;

      objNull = BoolModel()..field = null;
      objFalse = BoolModel()..field = false;
      objTrue = BoolModel()..field = true;
      objFalse2 = BoolModel()..field = false;

      await isar.writeTxn(() async {
        await col.putAll([objNull, objFalse, objTrue, objFalse2]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo() / .notEqualTo()', () async {
      // where clauses
      await qEqual(col.where().fieldEqualTo(true).tFindAll(), [objTrue]);
      await qEqual(
        col.where().fieldNotEqualTo(true).tFindAll(),
        [objNull, objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldEqualTo(false).tFindAll(),
        [objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(false).tFindAll(),
        [objNull, objTrue],
      );
      await qEqual(col.where().fieldEqualTo(null).tFindAll(), [objNull]);
      await qEqual(
        col.where().fieldNotEqualTo(null).tFindAll(),
        [objFalse, objFalse2, objTrue],
      );

      // filters
      await qEqual(col.filter().fieldEqualTo(true).tFindAll(), [objTrue]);
      await qEqual(
        col.filter().fieldEqualTo(false).tFindAll(),
        [objFalse, objFalse2],
      );
      await qEqual(col.where().fieldEqualTo(null).tFindAll(), [objNull]);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().fieldIsNull().tFindAll(), [objNull]);
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [objFalse, objFalse2, objTrue],
      );

      // filters
      await qEqualSet(col.where().filter().fieldIsNull().tFindAll(), [objNull]);
    });
  });

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

      objEmpty = BoolModel()..list = [];
      obj1 = BoolModel()..list = [true];
      obj2 = BoolModel()..list = [null, false];
      obj3 = BoolModel()..list = [true, false, true];
      objNull = BoolModel()..list = null;
      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyEqualTo() / .anyNotEqualTo()', () async {
      // where clauses
      await qEqualSet(
          col.where().listElementEqualTo(true).tFindAll(), [obj1, obj3]);
      await qEqualSet(col.where().listElementEqualTo(null).tFindAll(), [obj2]);
      await qEqualSet(
        col.where().listElementNotEqualTo(true).tFindAll(),
        [obj2, obj3],
      );

      await qEqualSet(
        col.where().listElementNotEqualTo(null).tFindAll(),
        [obj1, obj2, obj3],
      );

      // filters
      await qEqualSet(
        col.filter().listElementEqualTo(true).tFindAll(),
        [obj1, obj3],
      );
      await qEqualSet(col.filter().listElementEqualTo(null).tFindAll(), [obj2]);
    });
  });

  group('Bool hashList filter', () {
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

      objEmpty = BoolModel()..hashList = [];
      obj1 = BoolModel()..hashList = [true, null];
      obj2 = BoolModel()..hashList = [null, true];
      obj3 = BoolModel()..hashList = [true, null];
      objNull = BoolModel()..hashList = null;
      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo() / .notEqualTo()', () async {
      // where clauses
      await qEqualSet(col.where().hashListEqualTo(null).tFindAll(), [objNull]);
      await qEqualSet(col.where().hashListEqualTo([]).tFindAll(), [objEmpty]);
      await qEqualSet(
        col.where().hashListEqualTo([true, null]).tFindAll(),
        [obj1, obj3],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([]).tFindAll(),
        [objNull, obj1, obj2, obj3],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([true, null]).tFindAll(),
        [objNull, obj2, objEmpty],
      );

      // filters
      await qEqualSet(
        col.filter().hashListElementEqualTo(true).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(
          col.filter().hashListElementEqualTo(false).tFindAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().hashListIsNull().tFindAll(), [objNull]);
      await qEqualSet(
        col.where().hashListIsNotNull().findAll(),
        [obj1, obj2, obj3, objEmpty],
      );

      // filters
      await qEqualSet(col.filter().hashListIsNull().tFindAll(), [objNull]);
    });
  });
}
