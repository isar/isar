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
      isar = openIsar(dir.path);
      col = isar.intIndexs;

      isar.writeTxnSync((isar) {
        for (var i = 0; i < 5; i++) {
          final obj = IntIndex()..field = i;
          col.putSync(obj);
        }
        col.putSync(IntIndex()..field = null);
      });
    });

    test('where equalTo()', () {
      expect(
        col.where().fieldEqualTo(2).findAllSync(),
        [IntIndex()..field = 2],
      );

      expect(
        col.where().fieldEqualTo(null).findAllSync(),
        [IntIndex()..field = null],
      );

      expect(
        col.where().fieldEqualTo(5).findAllSync(),
        [],
      );
    });

    test('where notEqualTo()', () {
      expect(
        col.where().fieldNotEqualTo(3).findAllSync(),
        [
          IntIndex()..field = null,
          IntIndex()..field = 0,
          IntIndex()..field = 1,
          IntIndex()..field = 2,
          IntIndex()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () {
      expect(
        col.where().fieldGreaterThan(3).findAllSync(),
        [IntIndex()..field = 4],
      );

      expect(
        col.where().fieldGreaterThan(3, include: true).findAllSync(),
        [IntIndex()..field = 3, IntIndex()..field = 4],
      );

      expect(
        col.where().fieldGreaterThan(4).findAllSync(),
        [],
      );
    });

    test('where lowerThan()', () {
      expect(
        col.where().fieldLowerThan(1).findAllSync(),
        [IntIndex()..field = null, IntIndex()..field = 0],
      );

      expect(
        col.where().fieldLowerThan(1, include: true).findAllSync(),
        [
          IntIndex()..field = null,
          IntIndex()..field = 0,
          IntIndex()..field = 1
        ],
      );
    });

    test('where between()', () {
      expect(
        col.where().fieldBetween(1, 3).findAllSync(),
        [IntIndex()..field = 1, IntIndex()..field = 2, IntIndex()..field = 3],
      );

      expect(
        col.where().fieldBetween(null, 0).findAllSync(),
        [IntIndex()..field = null, IntIndex()..field = 0],
      );

      expect(
        col.where().fieldBetween(1, 3, includeLower: false).findAllSync(),
        [IntIndex()..field = 2, IntIndex()..field = 3],
      );

      expect(
        col.where().fieldBetween(1, 3, includeUpper: false).findAllSync(),
        [IntIndex()..field = 1, IntIndex()..field = 2],
      );

      expect(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAllSync(),
        [IntIndex()..field = 2],
      );

      expect(
        col.where().fieldBetween(5, 6).findAllSync(),
        [],
      );
    });

    test('where isNull()', () {
      expect(
        col.where().fieldIsNull().findAllSync(),
        [IntIndex()..field = null],
      );
    });

    test('where isNotNull()', () {
      expect(
        col.where().fieldIsNotNull().findAllSync(),
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
