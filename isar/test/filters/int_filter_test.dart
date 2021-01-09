// @dart=2.8
import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/int_model.dart';

void main() {
  group('Filter bool', () {
    Isar isar;
    IsarCollection<IntModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.intModels;

      isar.writeTxnSync((isar) {
        for (var i = 0; i < 5; i++) {
          final obj = IntModel()..field = i;
          col.putSync(obj);
        }
        col.putSync(IntModel()..field = null);
      });
    });

    test('where equalTo()', () {
      expect(
        col.where().filter().fieldEqualTo(2).findAllSync(),
        [IntModel()..field = 2],
      );

      expect(
        col.where().filter().fieldEqualTo(null).findAllSync(),
        [IntModel()..field = null],
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
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 4,
        ],
      );
    });

    test('where greaterThan()', () {
      expect(
        col.where().filter().fieldGreaterThan(3).findAllSync(),
        [IntModel()..field = 4],
      );

      expect(
        col.where().filter().fieldGreaterThan(3, include: true).findAllSync(),
        {IntModel()..field = 3, IntModel()..field = 4},
      );

      expect(
        col.where().filter().fieldGreaterThan(4).findAllSync(),
        [],
      );
    });

    test('where lowerThan()', () {
      expect(
        col.where().filter().fieldLowerThan(1).findAllSync().toSet(),
        {IntModel()..field = null, IntModel()..field = 0},
      );

      expect(
        col
            .where()
            .filter()
            .fieldLowerThan(1, include: true)
            .findAllSync()
            .toSet(),
        {
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1
        },
      );
    });

    test('where between()', () {
      expect(
        col.where().filter().fieldBetween(1, 3).findAllSync().toSet(),
        {IntModel()..field = 1, IntModel()..field = 2, IntModel()..field = 3},
      );

      expect(
        col.where().filter().fieldBetween(null, 0).findAllSync().toSet(),
        {IntModel()..field = null, IntModel()..field = 0},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false)
            .findAllSync()
            .toSet(),
        {IntModel()..field = 2, IntModel()..field = 3},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeUpper: false)
            .findAllSync()
            .toSet(),
        {IntModel()..field = 1, IntModel()..field = 2},
      );

      expect(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAllSync(),
        [IntModel()..field = 2],
      );

      expect(
        col.where().filter().fieldBetween(5, 6).findAllSync(),
        [],
      );
    });

    test('where isNull()', () {
      expect(
        col.where().filter().fieldIsNull().findAllSync(),
        [IntModel()..field = null],
      );
    });

    test('where isNotNull()', () {
      expect(
        col.where().filter().fieldIsNotNull().findAllSync().toSet(),
        {
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = 4,
        },
      );
    });
  });
}
