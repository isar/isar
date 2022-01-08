import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/double_model.dart';
import 'package:test/test.dart';

void main() {
  group('Double filter', () {
    late Isar isar;
    late IsarCollection<DoubleModel> col;

    late DoubleModel obj0;
    late DoubleModel obj1;
    late DoubleModel obj2;
    late DoubleModel obj3;
    late DoubleModel objInf;
    late DoubleModel objNull;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);
      col = isar.doubleModels;

      obj0 = DoubleModel()..field = 0;
      obj1 = DoubleModel()..field = 1.1;
      obj2 = DoubleModel()..field = 2.2;
      obj3 = DoubleModel()..field = 3.3;
      objInf = DoubleModel()..field = double.infinity;
      objNull = DoubleModel()..field = null;

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

  group('Double list filter', () {
    late Isar isar;
    late IsarCollection<DoubleModel> col;

    late DoubleModel objEmpty;
    late DoubleModel obj1;
    late DoubleModel obj2;
    late DoubleModel obj3;
    late DoubleModel objNull;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);
      col = isar.doubleModels;

      objEmpty = DoubleModel()..list = [];
      obj1 = DoubleModel()..list = [1.1, 3.3];
      obj2 = DoubleModel()..list = [null];
      obj3 = DoubleModel()..list = [null, double.negativeInfinity];
      objNull = DoubleModel()..list = null;

      await isar.writeTxn((isar) async {
        await col.putAll([objEmpty, obj1, obj3, obj2, objNull]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyGreaterThan() / .anyLessThan()', () async {
      // where clauses
      /*await qEqualSet(col.where().listAnyGreaterThan(1.1).findAll(), [obj1]);
      await qEqualSet(col.where().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(col.where().listAnyLessThan(1.1).findAll(), [obj2, obj3]);
      await qEqualSet(col.where().listAnyLessThan(null).findAll(), []);*/

      // filters
      //await qEqualSet(col.filter().listAnyGreaterThan(1.1).findAll(), [obj1]);
      //await qEqualSet(col.filter().listAnyGreaterThan(4).findAll(), []);
      await qEqualSet(
        col.filter().listAnyLessThan(1.1).findAll(),
        [obj2, obj3],
      );
      await qEqualSet(col.filter().listAnyLessThan(null).findAll(), []);
    });
  });
}
