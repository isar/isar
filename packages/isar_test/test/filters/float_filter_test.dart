import 'package:isar/isar.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/common.dart';
import 'package:isar_test/float_model.dart';
import 'package:test/test.dart';

void main() {
  group('Float filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = FloatModel()..field = i.toDouble() + i.toDouble() / 10;
          await col.put(obj);
        }
        await col.put(FloatModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3.3).findAll(),
        [FloatModel()..field = 4.4],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(3.3).findAll(),
        [FloatModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4.4).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(4.4).findAll(),
        [],
      );
    });

    isarTest('.lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(1.1).findAll(),
        [FloatModel()..field = null, FloatModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1.1).findAll(),
        {FloatModel()..field = null, FloatModel()..field = 0},
      );

      await qEqual(
        col.where().fieldLessThan(null).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldLessThan(null).findAll(),
        [],
      );
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().fieldBetween(1.1, 3.3).findAll(),
        [
          FloatModel()..field = 1.1,
          FloatModel()..field = 2.2,
          FloatModel()..field = 3.3
        ],
      );
      await qEqualSet(
        col.where().fieldBetween(1.1, 3.3).findAll(),
        {
          FloatModel()..field = 1.1,
          FloatModel()..field = 2.2,
          FloatModel()..field = 3.3
        },
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [FloatModel()..field = null, FloatModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).findAll(),
        {FloatModel()..field = null, FloatModel()..field = 0},
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [FloatModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [FloatModel()..field = null],
      );
    });

    isarTest('where .isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          FloatModel()..field = 0,
          FloatModel()..field = 1.1,
          FloatModel()..field = 2.2,
          FloatModel()..field = 3.3,
          FloatModel()..field = 4.4,
        ],
      );
    });
  });
}
