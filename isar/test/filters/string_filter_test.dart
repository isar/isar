import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/string_model.dart';

void main() {
  group('String filter', () {
    Isar isar;
    late IsarCollection<int, StringModel> col;

    setUp(() async {
      setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.stringModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = StringModel()..field = 'string_$i';
          await col.put(obj);
        }
        await col.put(StringModel()..field = null);
        await col.put(StringModel()..field = '');
        await col.put(StringModel()..field = 'string_4');
      });
    });

    test('equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo('string_2').findAll(),
        [StringModel()..field = 'string_2'],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('string_2').findAll(),
        [StringModel()..field = 'string_2'],
      );

      await qEqual(
        col.where().fieldEqualTo('string_4').findAll(),
        [
          StringModel()..field = 'string_4',
          StringModel()..field = 'string_4',
        ],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('string_4').findAll(),
        [
          StringModel()..field = 'string_4',
          StringModel()..field = 'string_4',
        ],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [StringModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [StringModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo('string_5').findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('string_5').findAll(),
        [],
      );

      await qEqual(
        col.where().fieldEqualTo('').findAll(),
        [StringModel()..field = ''],
      );
      await qEqual(
        col.where().filter().fieldEqualTo('').findAll(),
        [StringModel()..field = ''],
      );
    });

    test('isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [StringModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [StringModel()..field = null],
      );
    });

    test('isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_1',
          StringModel()..field = 'string_2',
          StringModel()..field = 'string_3',
          StringModel()..field = 'string_4',
          StringModel()..field = '',
          StringModel()..field = 'string_4',
        },
      );
      await qEqualSet(
        col.where().filter().not().fieldIsNull().findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_1',
          StringModel()..field = 'string_2',
          StringModel()..field = 'string_3',
          StringModel()..field = 'string_4',
          StringModel()..field = '',
          StringModel()..field = 'string_4',
        },
      );
    });

    test('isNotEqualTo()', () async {
      await qEqualSet(
        col.where().fieldNotEqualTo('string_4').findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_1',
          StringModel()..field = 'string_2',
          StringModel()..field = 'string_3',
          StringModel()..field = '',
        },
      );
      await qEqualSet(
        col.where().filter().not().fieldEqualTo('string_4').findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_1',
          StringModel()..field = 'string_2',
          StringModel()..field = 'string_3',
          StringModel()..field = '',
        },
      );
    });

    test('anyOf()', () async {
      await qEqualSet(
        col.where().fieldAnyOf(['string_4', 'string_0']).findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_4',
          StringModel()..field = 'string_4',
        },
      );

      await qEqualSet(
        col.where().fieldAnyOf(['', null, 'string_999']).findAll(),
        {
          StringModel()..field = '',
          StringModel()..field = null,
        },
      );

      await qEqual(
        col.where().fieldAnyOf([]).findAll(),
        [],
      );
    });

    test('between()', () async {
      await qEqualSet(
        col.where().fieldBetween('string_0', 'string_2').findAll(),
        {
          StringModel()..field = 'string_0',
          StringModel()..field = 'string_1',
          StringModel()..field = 'string_2',
        },
      );

      await qEqual(
        col.where().fieldBetween('string_0', null).findAll(),
        [],
      );

      await qEqual(
        col.where().fieldBetween('string_2', 'string_0').findAll(),
        [],
      );
    });
  });
}
