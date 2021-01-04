// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/long_index.dart';

void main() {
  group('Long index', () {
    Isar isar;
    IsarCollection<LongIndex> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = openIsar(dir.path);
      col = isar.longIndexs;

      isar.writeTxnSync((isar) {
        for (var i = 0; i < 5; i++) {
          final obj = LongIndex()..field = i;
          col.putSync(obj);
        }
        col.putSync(LongIndex()..field = null);
      });
    });

    test('where equalTo()', () {
      expect(
        col.where().fieldEqualTo(2).findAllSync(),
        [LongIndex()..field = 2],
      );

      expect(
        col.where().fieldEqualTo(null).findAllSync(),
        [LongIndex()..field = null],
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
          LongIndex()..field = null,
          LongIndex()..field = 0,
          LongIndex()..field = 1,
          LongIndex()..field = 2,
          LongIndex()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () {
      expect(
        col.where().fieldGreaterThan(3).findAllSync(),
        [LongIndex()..field = 4],
      );

      expect(
        col.where().fieldGreaterThan(3, include: true).findAllSync(),
        [LongIndex()..field = 3, LongIndex()..field = 4],
      );

      expect(
        col.where().fieldGreaterThan(4).findAllSync(),
        [],
      );
    });

    test('where lowerThan()', () {
      expect(
        col.where().fieldLowerThan(1).findAllSync(),
        [LongIndex()..field = null, LongIndex()..field = 0],
      );

      expect(
        col.where().fieldLowerThan(1, include: true).findAllSync(),
        [
          LongIndex()..field = null,
          LongIndex()..field = 0,
          LongIndex()..field = 1
        ],
      );
    });

    test('where between()', () {
      expect(
        col.where().fieldBetween(1, 3).findAllSync(),
        [
          LongIndex()..field = 1,
          LongIndex()..field = 2,
          LongIndex()..field = 3
        ],
      );

      expect(
        col.where().fieldBetween(null, 0).findAllSync(),
        [LongIndex()..field = null, LongIndex()..field = 0],
      );

      expect(
        col.where().fieldBetween(1, 3, includeLower: false).findAllSync(),
        [LongIndex()..field = 2, LongIndex()..field = 3],
      );

      expect(
        col.where().fieldBetween(1, 3, includeUpper: false).findAllSync(),
        [LongIndex()..field = 1, LongIndex()..field = 2],
      );

      expect(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAllSync(),
        [LongIndex()..field = 2],
      );

      expect(
        col.where().fieldBetween(5, 6).findAllSync(),
        [],
      );
    });

    test('where isNull()', () {
      expect(
        col.where().fieldIsNull().findAllSync(),
        [LongIndex()..field = null],
      );
    });

    test('where isNotNull()', () {
      expect(
        col.where().fieldIsNotNull().findAllSync(),
        [
          LongIndex()..field = 0,
          LongIndex()..field = 1,
          LongIndex()..field = 2,
          LongIndex()..field = 3,
          LongIndex()..field = 4,
        ],
      );
    });
  });
}
