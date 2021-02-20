import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/long_model.dart';

void main() {
  group('Long filter', () {
    Isar isar;
    late IsarCollection<int, LongModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.longModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = LongModel()..field = i;
          await col.put(obj);
        }
        await col.put(LongModel()..field = null);
      });
    });

    test('equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(2).findAll(),
        [LongModel()..field = 2],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(2).findAll(),
        [LongModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [LongModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo(5).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(5).findAll(),
        [],
      );
    });

    test('greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3).findAll(),
        [LongModel()..field = 4],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(3).findAll(),
        [LongModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3, include: true).findAll(),
        [LongModel()..field = 3, LongModel()..field = 4],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(3, include: true).findAll(),
        {LongModel()..field = 3, LongModel()..field = 4},
      );

      await qEqual(
        col.where().fieldGreaterThan(4).findAll(),
        [],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    test('lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(1).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1).findAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );

      await qEqual(
        col.where().fieldLessThan(1, include: true).findAll(),
        [
          LongModel()..field = null,
          LongModel()..field = 0,
          LongModel()..field = 1
        ],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1, include: true).findAll(),
        {
          LongModel()..field = null,
          LongModel()..field = 0,
          LongModel()..field = 1
        },
      );
    });

    test('between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).findAll(),
        [
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        ],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3).findAll(),
        {
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        },
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).findAll(),
        {LongModel()..field = null, LongModel()..field = 0},
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeLower: false).findAll(),
        [LongModel()..field = 2, LongModel()..field = 3],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3, includeLower: false).findAll(),
        {LongModel()..field = 2, LongModel()..field = 3},
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeUpper: false).findAll(),
        [LongModel()..field = 1, LongModel()..field = 2],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3, includeUpper: false).findAll(),
        {LongModel()..field = 1, LongModel()..field = 2},
      );

      await qEqual(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [LongModel()..field = 2],
      );
      await qEqual(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [LongModel()..field = 2],
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

    test('.in()', () async {
      await qEqual(
        col.where().fieldIn([null, 2, 3]).findAll(),
        [
          LongModel()..field = null,
          LongModel()..field = 2,
          LongModel()..field = 3,
        ],
      );
      await qEqual(
        col.where().filter().fieldIn([null, 2, 3]).findAll(),
        [
          LongModel()..field = 2,
          LongModel()..field = 3,
          LongModel()..field = null,
        ],
      );

      expect(() => col.where().fieldIn([]), throwsA(anything));
      expect(() => col.where().filter().fieldIn([]), throwsA(anything));
    });

    test('isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [LongModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [LongModel()..field = null],
      );
    });

    test('isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        {
          LongModel()..field = 0,
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3,
          LongModel()..field = 4,
        },
      );
    });
  });
}
