import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/float_model.dart';
import 'package:test/test.dart';

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

      await isar.writeTxn((isar) async {
        await col.putAll([objInf, obj0, obj2, obj1, obj3, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.greaterThan()', () async {
      // where clauses
      await qEqual(
        col.where().fieldGreaterThan(null).findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqual(col.where().fieldGreaterThan(2.2).findAll(), [obj3, objInf]);
      await qEqual(col.where().fieldGreaterThan(double.infinity).findAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldGreaterThan(null).findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqualSet(
        col.filter().fieldGreaterThan(2.2).findAll(),
        [obj3, objInf],
      );
      await qEqualSet(
          col.filter().fieldGreaterThan(double.infinity).findAll(), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().fieldLessThan(1.1).findAll(), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null).findAll(), []);

      await qEqualSet(
        col.filter().fieldLessThan(1.1).findAll(),
        [objNull, obj0],
      );
      await qEqualSet(col.filter().fieldLessThan(null).findAll(), []);
    });

    isarTest('.between()', () async {
      // where clauses
      await qEqual(
        col.where().fieldBetween(1.0, 3.5).findAll(),
        [obj1, obj2, obj3],
      );
      await qEqual(col.where().fieldBetween(5, 6).findAll(), []);

      // filters
      await qEqualSet(
        col.filter().fieldBetween(1.0, 3.5).findAll(),
        [obj1, obj2, obj3],
      );
      await qEqualSet(col.filter().fieldBetween(5, 6).findAll(), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull().findAll(), [objNull]);
      await qEqual(
        col.where().fieldIsNotNull().findAll(),
        [obj0, obj1, obj2, obj3, objInf],
      );

      await qEqual(col.filter().fieldIsNull().findAll(), [objNull]);
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
      obj3 = FloatModel()..list = [null, double.negativeInfinity];
      objNull = FloatModel()..list = null;

      await isar.writeTxn((isar) async {
        await col.putAll([objEmpty, obj1, obj3, obj2, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyGreaterThan() / .anyLessThan()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyGreaterThan(1.1).findAll(), [obj1]);
      await qEqualSet(col.where().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(col.where().listAnyLessThan(1.1).findAll(), [obj2, obj3]);
      await qEqualSet(col.where().listAnyLessThan(null).findAll(), []);

      // filters
      await qEqualSet(col.filter().listAnyGreaterThan(1.1).findAll(), [obj1]);
      await qEqualSet(col.filter().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(
        col.filter().listAnyLessThan(1.1).findAll(),
        [obj2, obj3],
      );
      await qEqualSet(col.filter().listAnyLessThan(null).findAll(), []);
    });

    isarTest('.anyBetween()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyBetween(1, 5).findAll(), [obj1]);
      await qEqualSet(col.where().listAnyBetween(5.0, 10.0).findAll(), []);

      // filters
      await qEqualSet(col.filter().listAnyBetween(1, 5).findAll(), [obj1]);
      await qEqualSet(col.filter().listAnyBetween(5.0, 10.0).findAll(), []);
    });

    isarTest('.anyIsNull() / .anyIsNotNull()', () async {
      // where clauses
      await qEqualSet(col.where().listAnyIsNull().findAll(), [obj2, obj3]);
      await qEqualSet(col.where().listAnyIsNotNull().findAll(), [obj1, obj3]);

      // filters
      await qEqualSet(col.filter().listAnyIsNull().findAll(), [obj2, obj3]);
    });
  });
}
