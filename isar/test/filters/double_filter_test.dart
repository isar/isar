import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/double_model.dart';

void main() {
  group('Double filter', () {
    Isar isar;
    late IsarCollection<int, DoubleModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.doubleModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = DoubleModel()..field = i.toDouble() + i.toDouble() / 10;
          await col.put(obj);
        }
        await col.put(DoubleModel()..field = null);
      });
    });

    test('greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3.3).findAll(),
        [DoubleModel()..field = 4.4],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(3.3).findAll(),
        [DoubleModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3.3, include: true).findAll(),
        [DoubleModel()..field = 3.3, DoubleModel()..field = 4.4],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(3.3, include: true).findAll(),
        {DoubleModel()..field = 3.3, DoubleModel()..field = 4.4},
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

    test('lowerThan()', () async {
      await qEqual(
        col.where().fieldLowerThan(1.1).findAll(),
        [DoubleModel()..field = null, DoubleModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLowerThan(1.1).findAll(),
        {DoubleModel()..field = null, DoubleModel()..field = 0},
      );

      await qEqual(
        col.where().fieldLowerThan(1.1, include: true).findAll(),
        [
          DoubleModel()..field = null,
          DoubleModel()..field = 0,
          DoubleModel()..field = 1.1
        ],
      );
      await qEqualSet(
        col.where().filter().fieldLowerThan(1.1, include: true).findAll(),
        [
          DoubleModel()..field = null,
          DoubleModel()..field = 0,
          DoubleModel()..field = 1.1
        ],
      );

      await qEqual(
        col.where().fieldLowerThan(null).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldLowerThan(null).findAll(),
        [],
      );
    });

    test('between()', () async {
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
        col
            .where()
            .fieldBetween(1.1, 3.3, includeLower: false, includeUpper: false)
            .findAll(),
        [
          DoubleModel()..field = 2.2,
        ],
      );
      await qEqual(
        col
            .where()
            .filter()
            .fieldBetween(1.1, 3.3, includeLower: false, includeUpper: false)
            .findAll(),
        [
          DoubleModel()..field = 2.2,
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

    test('isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [DoubleModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [DoubleModel()..field = null],
      );
    });

    test('isNotNull()', () async {
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
