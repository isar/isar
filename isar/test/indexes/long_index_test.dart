// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/long_model.dart';

void main() {
  group('Long index', () {
    Isar isar;
    IsarCollection<LongModel> col;

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

    test('where equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(2).findAll(),
        [LongModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [LongModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo(5).findAll(),
        [],
      );
    });

    test('where notEqualTo()', () async {
      await qEqualSet(
        col.where().fieldNotEqualTo(3).findAll(),
        [
          LongModel()..field = null,
          LongModel()..field = 0,
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3).findAll(),
        [LongModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3, include: true).findAll(),
        [LongModel()..field = 3, LongModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    test('where lowerThan()', () async {
      await qEqual(
        col.where().fieldLowerThan(1).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );

      await qEqual(
        col.where().fieldLowerThan(1, include: true).findAll(),
        [
          LongModel()..field = null,
          LongModel()..field = 0,
          LongModel()..field = 1
        ],
      );
    });

    test('where between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).findAll(),
        [
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3
        ],
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [LongModel()..field = null, LongModel()..field = 0],
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeLower: false).findAll(),
        [LongModel()..field = 2, LongModel()..field = 3],
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeUpper: false).findAll(),
        [LongModel()..field = 1, LongModel()..field = 2],
      );

      await qEqual(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [LongModel()..field = 2],
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    test('where isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [LongModel()..field = null],
      );
    });

    test('where isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          LongModel()..field = 0,
          LongModel()..field = 1,
          LongModel()..field = 2,
          LongModel()..field = 3,
          LongModel()..field = 4,
        ],
      );
    });
  });
}
