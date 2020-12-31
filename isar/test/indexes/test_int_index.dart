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
        for (var i = 0; i < 10; i++) {
          final obj = IntIndex()..field = i;
          col.putSync(obj);
        }
      });
    });

    test('where equalTo()', () {
      expect(
        col.where().fieldEqualTo(2).findAllSync(),
        [IntIndex()..field = 2],
      );

      expect(
        col.where().fieldEqualTo(10).findAllSync(),
        [],
      );
    });

    test('where notEqualTo()', () {
      expect(
        col.where().fieldNotEqualTo(3).findAllSync(),
        [
          IntIndex()..field = 0,
          IntIndex()..field = 1,
          IntIndex()..field = 2,
          IntIndex()..field = 4,
          IntIndex()..field = 5,
          IntIndex()..field = 6,
          IntIndex()..field = 7,
          IntIndex()..field = 8,
          IntIndex()..field = 9,
        ],
      );
    });

    test('where greaterThan()', () {
      expect(
        col.where().fieldGreaterThan(8).findAllSync(),
        [IntIndex()..field = 9],
      );

      expect(
        col.where().fieldGreaterThan(8, include: true).findAllSync(),
        [IntIndex()..field = 8, IntIndex()..field = 9],
      );

      expect(
        col.where().fieldGreaterThan(9).findAllSync(),
        [],
      );
    });

    test('where lowerThan()', () {
      expect(
        col.where().fieldLowerThan(1).findAllSync(),
        [IntIndex()..field = 0],
      );

      expect(
        col.where().fieldLowerThan(1, include: true).findAllSync(),
        [IntIndex()..field = 0, IntIndex()..field = 1],
      );

      expect(
        col.where().fieldLowerThan(0).findAllSync(),
        [],
      );
    });

    test('where between()', () {
      expect(
        col.where().fieldBetween(1, 3).findAllSync(),
        [IntIndex()..field = 1, IntIndex()..field = 2, IntIndex()..field = 3],
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
        col.where().fieldBetween(10, 11).findAllSync(),
        [],
      );
    });
  });
}
