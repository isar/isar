import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'filter_id_test.g.dart';

@Collection()
class IdModel {
  IdModel();
  @Id()
  int? id;

  @override
  String toString() {
    return '{id: $id}';
  }

  @override
  bool operator ==(Object other) {
    // ignore: test_types_in_equals
    return (other as IdModel).id == id;
  }
}

void main() {
  group('Int filter', () {
    late Isar isar;
    late IsarCollection<IdModel> col;

    late IdModel obj0;
    late IdModel obj1;
    late IdModel obj2;
    late IdModel obj3;

    setUp(() async {
      isar = await openTempIsar([IdModelSchema]);
      col = isar.idModels;

      obj0 = IdModel()..id = 0;
      obj1 = IdModel()..id = 1;
      obj2 = IdModel()..id = 2;
      obj3 = IdModel()..id = 3;

      await isar.writeTxn(() async {
        await isar.idModels.putAll([obj0, obj2, obj3, obj1]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo()', () async {
      // where clause
      await qEqual(col.where().idEqualTo(2).tFindAll(), [obj2]);
      await qEqual(col.where().idEqualTo(5).tFindAll(), []);

      // filters
      await qEqualSet(col.filter().idEqualTo(2).tFindAll(), [obj2]);
      await qEqualSet(col.filter().idEqualTo(5).tFindAll(), []);
    });

    isarTest('.greaterThan()', () async {
      // where clause
      await qEqual(col.where().idGreaterThan(2).tFindAll(), [obj3]);
      await qEqual(
        col.where().idGreaterThan(2, include: true).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(col.where().idGreaterThan(3).tFindAll(), []);

      // filters
      await qEqual(col.filter().idGreaterThan(2).tFindAll(), [obj3]);
      await qEqual(
        col.filter().idGreaterThan(2, include: true).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(col.filter().idGreaterThan(3).tFindAll(), []);
    });

    isarTest('.lessThan()', () async {
      // where clauses
      await qEqual(col.where().idLessThan(1).tFindAll(), [obj0]);
      await qEqual(
          col.where().idLessThan(1, include: true).tFindAll(), [obj0, obj1]);
      await qEqual(col.where().idLessThan(-1).tFindAll(), []);

      // filters
      await qEqual(col.filter().idLessThan(1).tFindAll(), [obj0]);
      await qEqual(
          col.filter().idLessThan(1, include: true).tFindAll(), [obj0, obj1]);
      await qEqual(col.filter().idLessThan(0).tFindAll(), []);
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().idBetween(1, 3).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.where().idBetween(1, 3, includeLower: false).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(
        col.where().idBetween(1, 3, includeUpper: false).tFindAll(),
        [obj1, obj2],
      );
      await qEqual(
        col
            .where()
            .idBetween(1, 3, includeLower: false, includeUpper: false)
            .tFindAll(),
        [obj2],
      );
      await qEqual(col.where().idBetween(5, 6).tFindAll(), []);

      // filters
      await qEqual(
        col.filter().idBetween(1, 3).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().idBetween(1, 3, includeLower: false).tFindAll(),
        [obj2, obj3],
      );
      await qEqual(
        col.filter().idBetween(1, 3, includeUpper: false).tFindAll(),
        [obj1, obj2],
      );
      await qEqual(
        col
            .filter()
            .idBetween(1, 3, includeLower: false, includeUpper: false)
            .tFindAll(),
        [obj2],
      );
      await qEqual(col.filter().idBetween(5, 6).tFindAll(), []);
    });
  });
}
