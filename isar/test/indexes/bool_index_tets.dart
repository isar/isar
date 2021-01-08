// @dart=2.8
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/bool_index.dart';

void main() {
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
        col
            .where()
            .fieldEqualTo(true)
            .filter()
            .fieldEqualTo(true)
            .fieldEqualTo(true)
            .fieldEqualTo(true)
            .group((q) {
          return q.fieldIsNotNull().or().fieldIsNull();
        }),
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
