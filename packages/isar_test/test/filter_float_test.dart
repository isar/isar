import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'filter_float_test.g.dart';

@Collection()
class FloatModel {
  FloatModel();
  @Id()
  int? id;

  @Index()
  double? field = 0;

  @Index(type: IndexType.value)
  @Size32()
  List<double?>? list;

  @override
  String toString() {
    return '{id: $id, field: $field, list: $list}';
  }

  @override
  bool operator ==(Object other) {
    // ignore: test_types_in_equals
    final FloatModel otherModel = other as FloatModel;
    if ((other.field == null) != (field == null)) {
      return false;
    } else if (id != other.id) {
      return false;
    } else if (field != null && (otherModel.field! - field!).abs() > 0.001) {
      return false;
    } else if (!doubleListEquals(list, other.list)) {
      return false;
    }

    return true;
  }
}

void main() {
  group('Float filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel obj0;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objInf;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      obj0 = FloatModel()..field = 0;
      obj1 = FloatModel()..field = 1.1;
      obj2 = FloatModel()..field = 2.2;
      obj3 = FloatModel()..field = 3.3;
      objInf = FloatModel()..field = double.infinity;
      objNull = FloatModel()..field = null;

      await isar.writeTxn(() async {
        await col.putAll([objInf, obj0, obj2, obj1, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.greaterThan()', () async {
      // where clauses
      await qEqual(
        col.where().fieldGreaterThan(null).tFindAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqual(
          col.where().fieldGreaterThan(2.2).tFindAll(), [obj3, objInf]);
      await qEqual(
          col.where().fieldGreaterThan(double.infinity).tFindAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldGreaterThan(null).tFindAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(2.2).tFindAll(),
        [obj3, objInf],
      );
      await qEqualSet(
          col.filter().fieldGreaterThan(double.infinity).tFindAll(), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().fieldLessThan(1.1).tFindAll(), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null).tFindAll(), []);

      await qEqualSet(
        col.filter().fieldLessThan(1.1).tFindAll(),
        [objNull, obj0],
      );
      await qEqualSet(col.filter().fieldLessThan(null).tFindAll(), []);
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().fieldBetween(1.0, 3.5).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(col.where().fieldBetween(5, 6).tFindAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldBetween(1.0, 3.5).tFindAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(col.filter().fieldBetween(5, 6).tFindAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull().tFindAll(), [objNull]);
      await qEqual(
        col.where().fieldIsNotNull().tFindAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );

      await qEqual(col.filter().fieldIsNull().tFindAll(), [objNull]);
    });
  });

  group('Float list filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel objEmpty;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      objEmpty = FloatModel()..list = [];
      obj1 = FloatModel()..list = [1.1, 3.3];
      obj2 = FloatModel()..list = [null];
      obj3 = FloatModel()..list = [null, -1000];
      objNull = FloatModel()..list = null;

      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj3, obj2, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyGreaterThan() / .anyLessThan()', () async {
      // where clauses
      await qEqualSet(
          col.where().listElementGreaterThan(1.1).tFindAll(), [obj1]);
      await qEqualSet(col.where().listElementGreaterThan(4).tFindAll(), []);
      await qEqualSet(
          col.where().listElementLessThan(1.1).tFindAll(), [obj2, obj3]);
      await qEqualSet(col.where().listElementLessThan(null).tFindAll(), []);

      // filters
      await qEqualSet(
          col.filter().listElementGreaterThan(1.1).tFindAll(), [obj1]);
      await qEqualSet(col.filter().listElementGreaterThan(4).tFindAll(), []);
      await qEqualSet(
        col.filter().listElementLessThan(1.1).tFindAll(),
        [obj2, obj3],
      );
      await qEqualSet(col.filter().listElementLessThan(null).tFindAll(), []);
    });

    isarTest('.anyBetween()', () async {
      // where clauses
      await qEqualSet(col.where().listElementBetween(1, 5).tFindAll(), [obj1]);
      await qEqualSet(col.where().listElementBetween(5.0, 10.0).tFindAll(), []);

      // filters
      await qEqualSet(col.filter().listElementBetween(1, 5).tFindAll(), [obj1]);
      await qEqualSet(
          col.filter().listElementBetween(5.0, 10.0).tFindAll(), []);
    });

    isarTest('.anyIsNull() / .anyIsNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().listElementIsNull().tFindAll(), [obj2, obj3]);
      await qEqualSet(
          col.where().listElementIsNotNull().tFindAll(), [obj1, obj3]);

      // filters
      await qEqualSet(
          col.filter().listElementIsNull().tFindAll(), [obj2, obj3]);
    });
  });
}
