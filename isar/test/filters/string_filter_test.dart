import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/string_model.dart';

void main() {
  group('String filter', () {
    Isar isar;
    late IsarCollection<int, StringModel> col;

    setUp(() async {
      await setupIsar();

      final dir = await getTempDir();
      isar = await openIsar(directory: dir.path);
      col = isar.stringModels;

      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          final obj = StringModel.init('string $i');
          await col.put(obj);
        }
        await col.put(StringModel.init(null));
        await col.put(StringModel.init(''));
        await col.put(StringModel.init('string 4'));
      });
    });

    test('equalTo()', () async {
      await qEqual(
        col.where().hashFieldEqualTo('string 2').findAll(),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.where().valueFieldEqualTo('string 2').findAll(),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.where().wordsFieldWordEqualTo('2').findAll(),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.where().filter().hashFieldEqualTo('string 2').findAll(),
        [StringModel.init('string 2')],
      );

      await qEqual(
        col.where().hashFieldEqualTo(null).findAll(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().valueFieldEqualTo(null).findAll(),
        [StringModel.init(null)],
      );
      try {
        await col.where().wordsFieldWordEqualTo(null).findAll();
        fail('Should fail');
      } catch (e) {}
      await qEqual(
        col.where().filter().hashFieldEqualTo(null).findAll(),
        [StringModel.init(null)],
      );

      await qEqual(
        col.where().hashFieldEqualTo('string 5').findAll(),
        [],
      );
      await qEqual(
        col.where().valueFieldEqualTo('string 5').findAll(),
        [],
      );
      await qEqual(
        col.where().wordsFieldWordEqualTo('5').findAll(),
        [],
      );
      await qEqual(
        col.where().filter().hashFieldEqualTo('string 5').findAll(),
        [],
      );

      await qEqual(
        col.where().hashFieldEqualTo('').findAll(),
        [StringModel.init('')],
      );
      await qEqual(
        col.where().valueFieldEqualTo('').findAll(),
        [StringModel.init('')],
      );

      try {
        await col.where().wordsFieldWordEqualTo('').findAll();
        fail('Should fail');
      } catch (e) {}

      await qEqual(
        col.where().filter().hashFieldEqualTo('').findAll(),
        [StringModel.init('')],
      );
    });

    test('isNull()', () async {
      await qEqual(
        col.where().hashFieldIsNull().findAll(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().valueFieldIsNull().findAll(),
        [StringModel.init(null)],
      );

      await qEqual(
        col.where().filter().hashFieldIsNull().findAll(),
        [StringModel.init(null)],
      );
    });

    test('isNotNull()', () async {
      await qEqual(
        col.where().valueFieldIsNotNull().findAll(),
        [
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        ],
      );
    });

    /*test('isNotEqualTo()', () async {
      await qEqualSet(
        col.where().filter().not().fieldEqualTo('string_4').findAll(),
        {
          StringModel.init('string_0',
          StringModel.init('string_1',
          StringModel.init('string_2',
          StringModel.init('string_3',
          StringModel.init('',
        },
      );
    });

    test('anyOf()', () async {
      await qEqualSet(
        col.where().fieldAnyOf(['string_4', 'string_0']).findAll(),
        {
          StringModel.init('string_0',
          StringModel.init('string_4',
          StringModel.init('string_4',
        },
      );

      await qEqualSet(
        col.where().fieldAnyOf(['', null, 'string_999']).findAll(),
        {
          StringModel.init('',
          StringModel.init(null,
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
          StringModel.init('string_0',
          StringModel.init('string_1',
          StringModel.init('string_2',
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
    });*/
  });
}
