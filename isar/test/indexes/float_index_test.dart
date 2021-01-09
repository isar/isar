// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/float_model.dart';

void main() {
  group('Float index', () {
    Isar isar;
    IsarCollection<FloatModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.floatModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = FloatModel()..field = i.toDouble() + i.toDouble() / 10;
          await col.put(obj);
        }
        await col.put(FloatModel()..field = null);
      });
    });

    test('where greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3.3).findAll(),
        [FloatModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3.3, include: true).findAll(),
        [FloatModel()..field = 3.3, FloatModel()..field = 4.4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4.4).findAll(),
        [],
      );
    });

    test('where lowerThan()', () async {
      await qEqual(
        col.where().fieldLowerThan(1.1).findAll(),
        [FloatModel()..field = null, FloatModel()..field = 0],
      );

      await qEqual(
        col.where().fieldLowerThan(1.1, include: true).findAll(),
        [
          FloatModel()..field = null,
          FloatModel()..field = 0,
          FloatModel()..field = 1.1
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
          FloatModel()..field = 1.1,
          FloatModel()..field = 2.2,
          FloatModel()..field = 3.3
        ],
      );

      await qEqual(
        col
            .where()
            .fieldBetween(1.1, 3.3, includeLower: false, includeUpper: false)
            .findAll(),
        [
          FloatModel()..field = 2.2,
        ],
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [FloatModel()..field = null, FloatModel()..field = 0],
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    test('where isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [FloatModel()..field = null],
      );
    });

    test('where isNotNull()', () async {
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
