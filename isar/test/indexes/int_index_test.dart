// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/int_index.dart';

void main() {
  group('Int index', () {
    Isar isar;
    IsarCollection<IntIndex> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(dir.path);
      col = isar.intIndexs;

      var obj;
      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          obj = IntIndex()..field = i;
          await col.put(obj);
        }
        await col.put(IntIndex()..field = null);
      });
    });

    test('where equalTo()', () async {
      expect(
        await col.where().fieldEqualTo(2).findAll(),
        [IntIndex()..field = 2],
      );

      expect(
        await col.where().fieldEqualTo(null).findAll(),
        [IntIndex()..field = null],
      );

      expect(
        await col.where().fieldEqualTo(5).findAll(),
        [],
      );
    });

    test('where notEqualTo()', () async {
      expect(
        await col.where().fieldNotEqualTo(3).findAll(),
        [
          IntIndex()..field = null,
          IntIndex()..field = 0,
          IntIndex()..field = 1,
          IntIndex()..field = 2,
          IntIndex()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () async {
      expect(
        await col.where().fieldGreaterThan(3).findAll(),
        [IntIndex()..field = 4],
      );

      expect(
        await col.where().fieldGreaterThan(3, include: true).findAll(),
        [IntIndex()..field = 3, IntIndex()..field = 4],
      );

      expect(
        await col.where().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    test('where lowerThan()', () async {
      expect(
        await col.where().fieldLowerThan(1).findAll(),
        [IntIndex()..field = null, IntIndex()..field = 0],
      );

      expect(
        await col.where().fieldLowerThan(1, include: true).findAll(),
        [
          IntIndex()..field = null,
          IntIndex()..field = 0,
          IntIndex()..field = 1
        ],
      );
    });

    test('where between()', () async {
      expect(
        await col.where().fieldBetween(1, 3).findAll(),
        [IntIndex()..field = 1, IntIndex()..field = 2, IntIndex()..field = 3],
      );

      expect(
        await col.where().fieldBetween(null, 0).findAll(),
        [IntIndex()..field = null, IntIndex()..field = 0],
      );

      expect(
        await col.where().fieldBetween(1, 3, includeLower: false).findAll(),
        [IntIndex()..field = 2, IntIndex()..field = 3],
      );

      expect(
        await col.where().fieldBetween(1, 3, includeUpper: false).findAll(),
        [IntIndex()..field = 1, IntIndex()..field = 2],
      );

      expect(
        await col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [IntIndex()..field = 2],
      );

      expect(
        await col.where().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    test('where isNull()', () async {
      expect(
        await col.where().fieldIsNull().findAll(),
        [IntIndex()..field = null],
      );
    });

    test('where isNotNull()', () async {
      expect(
        await col.where().fieldIsNotNull().findAll(),
        [
          IntIndex()..field = 0,
          IntIndex()..field = 1,
          IntIndex()..field = 2,
          IntIndex()..field = 3,
          IntIndex()..field = 4,
        ],
      );
    });
  });
}
