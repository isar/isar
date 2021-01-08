// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/bool_index.dart';

void main() {
  test('description', () async {
    Isar isar;
    IsarCollection<BoolIndex> col;

    setupIsar();

    final dir = await getTempDir();
    isar = await openIsar(dir.path);
    col = isar.boolIndexs;

    final t1 = BoolIndex()..field = true;
    isar.writeTxnSync((isar) {
      col.putSync(BoolIndex()..field = false);
      col.putSync(t1);
      col.putSync(BoolIndex()..field = false);
      col.putSync(BoolIndex()..field = null);
    });

    print(t1.id);

    final t2 = await col.get(t1.id);
    print(t2);
  });

  group('Bool index', () {
    Isar isar;
    IsarCollection<BoolIndex> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(dir.path);
      col = isar.boolIndexs;

      isar.writeTxnSync((isar) {
        col.putSync(BoolIndex()..field = false);
        col.putSync(BoolIndex()..field = true);
        col.putSync(BoolIndex()..field = false);
        col.putSync(BoolIndex()..field = null);
      });
    });

    test('where equalTo()', () {
      expect(
        col.where().fieldEqualTo(true).findAllSync(),
        [BoolIndex()..field = true],
      );

      expect(
        col.where().fieldEqualTo(null).findAllSync(),
        [BoolIndex()..field = null],
      );
    });

    test('where notEqualTo()', () {
      expect(
        col.where().fieldNotEqualTo(null).findAllSync(),
        [
          BoolIndex()..field = false,
          BoolIndex()..field = false,
          BoolIndex()..field = true
        ],
      );
      expect(
        col.where().fieldNotEqualTo(false).findAllSync(),
        [BoolIndex()..field = null, BoolIndex()..field = true],
      );
      expect(
        col.where().fieldNotEqualTo(true).findAllSync(),
        [
          BoolIndex()..field = null,
          BoolIndex()..field = false,
          BoolIndex()..field = false,
        ],
      );
    });

    test('where isNull()', () {
      expect(
        col.where().fieldIsNull().findAllSync(),
        [BoolIndex()..field = null],
      );
    });

    test('where isNotNull()', () {
      expect(
        col.where().fieldIsNotNull().findAllSync(),
        [
          BoolIndex()..field = false,
          BoolIndex()..field = false,
          BoolIndex()..field = true,
        ],
      );
    });
  });
}
