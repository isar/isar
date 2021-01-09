// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/int_model.dart';

void main() {
  group('Int index', () {
    Isar isar;
    IsarCollection<IntModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.intModels;

      var obj;
      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          obj = IntModel()..field = i;
          await col.put(obj);
        }
        await col.put(IntModel()..field = null);
      });
    });

    test('where equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(2).findAll(),
        [IntModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [IntModel()..field = null],
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
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3).findAll(),
        [IntModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3, include: true).findAll(),
        [IntModel()..field = 3, IntModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    test('where lowerThan()', () async {
      await qEqual(
        col.where().fieldLowerThan(1).findAll(),
        [IntModel()..field = null, IntModel()..field = 0],
      );

      await qEqual(
        col.where().fieldLowerThan(1, include: true).findAll(),
        [
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1
        ],
      );
    });

    test('where between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).findAll(),
        [IntModel()..field = 1, IntModel()..field = 2, IntModel()..field = 3],
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [IntModel()..field = null, IntModel()..field = 0],
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeLower: false).findAll(),
        [IntModel()..field = 2, IntModel()..field = 3],
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeUpper: false).findAll(),
        [IntModel()..field = 1, IntModel()..field = 2],
      );

      await qEqual(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [IntModel()..field = 2],
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    test('where isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [IntModel()..field = null],
      );
    });

    test('where isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = 4,
        ],
      );
    });
  });
}
