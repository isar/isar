// @dart=2.8
import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/int_index.dart';

void main() {
  group('Filter bool', () {
    Isar isar;
    IsarCollection<IntIndex> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(dir.path);
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
        col.where().filter().fieldEqualTo(2).findAllSync(),
        [IntIndex()..field = 2],
      );

      expect(
        col.where().filter().fieldEqualTo(null).findAllSync(),
        [IntIndex()..field = null],
      );

      expect(
        col.where().filter().fieldEqualTo(5).findAllSync(),
        [],
      );
    });

    test('where notEqualTo()', () {
      expect(
        col.where().filter().fieldNotEqualTo(3).findAllSync(),
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
        col.where().filter().fieldGreaterThan(3).findAllSync(),
        [IntIndex()..field = 4],
      );

      expect(
        col.where().filter().fieldGreaterThan(3, include: true).findAllSync(),
        {IntIndex()..field = 3, IntIndex()..field = 4},
      );

      expect(
        col.where().filter().fieldGreaterThan(4).findAllSync(),
        [],
      );
    });

    test('where lowerThan()', () {
      expect(
        col.where().filter().fieldLowerThan(1).findAllSync().toSet(),
        {IntIndex()..field = null, IntIndex()..field = 0},
      );

      expect(
        col
            .where()
            .filter()
            .fieldLowerThan(1, include: true)
            .findAllSync()
            .toSet(),
        {
          IntIndex()..field = null,
          IntIndex()..field = 0,
          IntIndex()..field = 1
        },
      );
    });

    test('where between()', () {
      expect(
        col.where().filter().fieldBetween(1, 3).findAllSync().toSet(),
        {IntIndex()..field = 1, IntIndex()..field = 2, IntIndex()..field = 3},
      );

      expect(
        col.where().filter().fieldBetween(null, 0).findAllSync().toSet(),
        {IntIndex()..field = null, IntIndex()..field = 0},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false)
            .findAllSync()
            .toSet(),
        {IntIndex()..field = 2, IntIndex()..field = 3},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeUpper: false)
            .findAllSync()
            .toSet(),
        {IntIndex()..field = 1, IntIndex()..field = 2},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAllSync(),
        [IntIndex()..field = 2],
      );

      expect(
        col.where().filter().fieldBetween(5, 6).findAllSync(),
        [],
      );
    });

    test('where isNull()', () {
      expect(
        col.where().filter().fieldIsNull().findAllSync(),
        [IntIndex()..field = null],
      );
    });

    test('where isNotNull()', () {
      expect(
        col.where().filter().fieldIsNotNull().findAllSync().toSet(),
        {
          IntIndex()..field = 0,
          IntIndex()..field = 1,
          IntIndex()..field = 2,
          IntIndex()..field = 3,
          IntIndex()..field = 4,
        },
      );
    });
  });
}
