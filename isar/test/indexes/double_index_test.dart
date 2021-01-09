// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/double_model.dart';

void main() {
  group('Double index', () {
    Isar isar;
    IsarCollection<DoubleModel> col;

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

    test('where greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3.3).findAll(),
        [DoubleModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3.3, include: true).findAll(),
        [DoubleModel()..field = 3.3, DoubleModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4.4).findAll(),
        [],
      );
    });

    test('where lowerThan()', () async {
      await qEqual(
        col.where().fieldLowerThan(1.1).findAll(),
        [DoubleModel()..field = null, DoubleModel()..field = 0],
      );

      await qEqual(
        col.where().fieldLowerThan(1.1, include: true).findAll(),
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
    });

    test('where between()', () async {
      await qEqual(
        col.where().fieldBetween(1.1, 3.3).findAll(),
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
        col.where().fieldBetween(null, 0).findAll(),
        [DoubleModel()..field = null, DoubleModel()..field = 0],
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    test('where isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [DoubleModel()..field = null],
      );
    });

    test('where isNotNull()', () async {
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
