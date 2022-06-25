import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_int_test.g.dart';

@Collection()
class IntModel {
  IntModel();
  @Id()
  int? id;

  @Index()
  @Size32()
  int? field = 0;

  @Index(type: IndexType.value)
  @Size32()
  List<int?>? list;

  @Index(type: IndexType.hash)
  @Size32()
  List<int>? hashList;

  @override
  String toString() {
    return '{id: $id, field: $field, list: $list}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IntModel &&
        other.field == field &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}

void main() {
  group('Int filter', () {
    late Isar isar;
    late IsarCollection<IntModel> col;

    late IntModel obj0;
    late IntModel obj1;
    late IntModel obj2;
    late IntModel obj3;
    late IntModel obj4;
    late IntModel objNull;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema]);
      col = isar.intModels;

      obj0 = IntModel()..field = 0;
      obj1 = IntModel()..field = 1;
      obj2 = IntModel()..field = 2;
      obj3 = IntModel()..field = 3;
      obj4 = IntModel()..field = 4;
      objNull = IntModel()..field = null;

      await isar.writeTxn(() async {
        await isar.intModels.putAll([obj4, obj0, obj2, obj3, obj1, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo()', () async {
      // where clause
      await qEqual(col.where().fieldEqualTo(2).tFindAll(), [obj2]);
      await qEqual(col.where().fieldEqualTo(null).tFindAll(), [objNull]);
      await qEqual(col.where().fieldEqualTo(5).tFindAll(), []);

      // filters
      await qEqualSet(col.filter().fieldEqualTo(2).tFindAll(), [obj2]);
      await qEqualSet(col.filter().fieldEqualTo(null).tFindAll(), [objNull]);
      await qEqualSet(col.filter().fieldEqualTo(5).tFindAll(), []);
    });

    isarTest('.greaterThan()', () async {
      // where clause
      await qEqual(col.where().fieldGreaterThan(3).tFindAll(), [obj4]);
      await qEqual(
        col.where().fieldGreaterThan(3, include: true).tFindAll(),
        [obj3, obj4],
      );
      await qEqual(
        col.where().fieldGreaterThan(null).tFindAll(),
        [obj0, obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col.where().fieldGreaterThan(null, include: true).tFindAll(),
        [objNull, obj0, obj1, obj2, obj3, obj4],
      );
      await qEqual(col.where().fieldGreaterThan(4).tFindAll(), []);

      // filters
      await qEqualSet(col.filter().fieldGreaterThan(3).tFindAll(), [obj4]);
      await qEqualSet(
        col.filter().fieldGreaterThan(3, include: true).tFindAll(),
        [obj3, obj4],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(null).tFindAll(),
        [obj0, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(null, include: true).tFindAll(),
        [objNull, obj0, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(col.filter().fieldGreaterThan(4).tFindAll(), []);
    });

    isarTest('.lessThan()', () async {
      // where clauses
      await qEqual(col.where().fieldLessThan(1).tFindAll(), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null).tFindAll(), []);
      await qEqual(
        col.where().fieldLessThan(null, include: true).tFindAll(),
        [objNull],
      );

      // filters
      await qEqualSet(
        col.filter().fieldLessThan(1).tFindAll(),
        [objNull, obj0],
      );
      await qEqualSet(col.filter().fieldLessThan(null).tFindAll(), []);
      await qEqualSet(
        col.filter().fieldLessThan(null, include: true).tFindAll(),
        [objNull],
      );
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().fieldBetween(1, 3).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.where().fieldBetween(1, 3, includeLower: false).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(
        col.where().fieldBetween(1, 3, includeUpper: false).tFindAll(),
        [obj1, obj2],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .tFindAll(),
        [obj2],
      );
      await qEqual(
        col.where().fieldBetween(null, 0).tFindAll(),
        [objNull, obj0],
      );
      await qEqual(col.where().fieldBetween(5, 6).tFindAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldBetween(1, 3).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(
        col.filter().fieldBetween(1, 3, includeLower: false).tFindAll(),
        [obj2, obj3],
      );
      await qEqualSet(
        col.filter().fieldBetween(1, 3, includeUpper: false).tFindAll(),
        [obj1, obj2],
      );
      await qEqualSet(
        col
            .filter()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .tFindAll(),
        [obj2],
      );
      await qEqualSet(
        col.filter().fieldBetween(null, 0).tFindAll(),
        [objNull, obj0],
      );
      await qEqualSet(col.filter().fieldBetween(5, 6).tFindAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull().tFindAll(), [objNull]);
      await qEqual(
        col.where().fieldIsNotNull().tFindAll(),
        [obj0, obj1, obj2, obj3, obj4],
      );

      await qEqual(col.filter().fieldIsNull().tFindAll(), [objNull]);
    });
  });
}
