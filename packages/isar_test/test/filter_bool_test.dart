import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'common.dart';

part 'filter_bool_test.g.dart';

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
    return '{id: $id, field: $field, list: $list, hashList: $hashList}';
  }

  @override
  bool operator ==(other) {
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

      await isar.writeTxn((isar) async {
        await col.putAll([objNull, objFalse, objTrue, objFalse2]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo() / .notEqualTo()', () async {
      // where clauses
      await qEqual(col.where().fieldEqualTo(true).findAll(), [objTrue]);
      await qEqual(
        col.where().fieldNotEqualTo(true).findAll(),
        [objNull, objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldEqualTo(false).findAll(),
        [objFalse, objFalse2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(false).findAll(),
        [objNull, objTrue],
      );
      await qEqual(col.where().fieldEqualTo(null).findAll(), [objNull]);
      await qEqual(
        col.where().fieldNotEqualTo(null).findAll(),
        [objFalse, objFalse2, objTrue],
      );

      // filters
      await qEqual(col.filter().fieldEqualTo(true).findAll(), [objTrue]);
      await qEqual(
        col.filter().fieldEqualTo(false).findAll(),
        [objFalse, objFalse2],
      );
      await qEqual(col.where().fieldEqualTo(null).findAll(), [objNull]);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().fieldIsNull().findAll(), [objNull]);
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [objFalse, objFalse2, objTrue],
      );

      // filters
      await qEqualSet(col.where().filter().fieldIsNull().findAll(), [objNull]);
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
      await isar.writeTxn((isar) async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyEqualTo() / .anyNotEqualTo()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyEqualTo(true).findAll(), [obj1, obj3]);
      await qEqualSet(col.where().listAnyEqualTo(null).findAll(), [obj2]);
      await qEqualSet(
        col.where().listAnyNotEqualTo(true).findAll(),
        [obj2, obj3],
      );

      await qEqualSet(
        col.where().listAnyNotEqualTo(null).findAll(),
        [obj1, obj2, obj3],
      );

      // filters
      await qEqualSet(
        col.filter().listAnyEqualTo(true).findAll(),
        [obj1, obj3],
      );
      await qEqualSet(col.filter().listAnyEqualTo(null).findAll(), [obj2]);
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
      await isar.writeTxn((isar) async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo() / .notEqualTo()', () async {
      // where clauses
      await qEqualSet(col.where().hashListEqualTo(null).findAll(), [objNull]);
      await qEqualSet(col.where().hashListEqualTo([]).findAll(), [objEmpty]);
      await qEqualSet(
        col.where().hashListEqualTo([true, null]).findAll(),
        [obj1, obj3],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([]).findAll(),
        [objNull, obj1, obj2, obj3],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([true, null]).findAll(),
        [objNull, obj2, objEmpty],
      );

      // filters
      await qEqualSet(
        col.filter().hashListAnyEqualTo(true).findAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(col.filter().hashListAnyEqualTo(false).findAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().hashListIsNull().findAll(), [objNull]);
      await qEqualSet(
        col.where().hashListIsNotNull().findAll(),
        [obj1, obj2, obj3, objEmpty],
      );

      // filters
      await qEqualSet(col.filter().hashListIsNull().findAll(), [objNull]);
    });
  });
}
