import 'package:isar/isar.dart';
import 'package:isar_test/utils/common.dart';
import 'package:isar_test/utils/open.dart';
import 'package:isar_test/double_model.dart';
import 'package:test/test.dart';

void main() {
  group('Double filter', () {
    late Isar isar;
    late IsarCollection<DoubleModel> col;

    setUp(() async {
      isar = await openTempIsar([DoubleModelSchema]);
      col = isar.doubleModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = DoubleModel()..field = i.toDouble() + i.toDouble() / 10;
          await col.put(obj);
        }
        await col.put(DoubleModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3.3).findAll(),
        [DoubleModel()..field = 4.4],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(3.3).findAll(),
        [DoubleModel()..field = 4.4],
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
        [DoubleModel()..field = null, DoubleModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1.1).findAll(),
        {DoubleModel()..field = null, DoubleModel()..field = 0},
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
          DoubleModel()..field = 1.1,
          DoubleModel()..field = 2.2,
          DoubleModel()..field = 3.3
        ],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1.1, 3.3).findAll(),
        [
          DoubleModel()..field = 1.1,
          DoubleModel()..field = 2.2,
          DoubleModel()..field = 3.3
        ],
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [DoubleModel()..field = null, DoubleModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).findAll(),
        {DoubleModel()..field = null, DoubleModel()..field = 0},
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
        [DoubleModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [DoubleModel()..field = null],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          DoubleModel()..field = 0,
          DoubleModel()..field = 1.1,
          DoubleModel()..field = 2.2,
          DoubleModel()..field = 3.3,
          DoubleModel()..field = 4.4,
        ],
      );
    });
  });
}
