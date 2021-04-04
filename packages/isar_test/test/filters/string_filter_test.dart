import 'package:isar/isar.dart';
import 'package:isar_test/isar.g.dart';
import 'package:isar_test/string_model.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  group('String filter', () {
    late Isar isar;
    late IsarCollection<StringModel> col;

    setUp(() async {
      isar = await openTempIsar();
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

    tearDown(() async {
      await isar.close();
    });

    isarTest('equalTo()', () async {
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
      } catch (e) {
        // do nothing
      }
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
      } catch (e) {
        // do nothing
      }

      await qEqual(
        col.where().filter().hashFieldEqualTo('').findAll(),
        [StringModel.init('')],
      );
    });

    isarTest('isNull()', () async {
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

    isarTest('isNotNull()', () async {
      await qEqualSet(
        col.where().hashFieldIsNotNull().findAll(),
        {
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

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

    isarTest('isNotEqualTo()', () async {
      await qEqualSet(
        col.where().hashFieldNotEqualTo('string 4').findAll(),
        {
          StringModel.init(null),
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
        },
      );
      await qEqualSet(
        col.where().valueFieldNotEqualTo('string 4').findAll(),
        [
          StringModel.init(null),
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
        ],
      );
    });

    isarTest('.startsWith()', () async {
      await qEqual(
        col.where().valueFieldStartsWith('string').findAll(),
        [
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        ],
      );
      await qEqualSet(
        col.where().filter().valueFieldStartsWith('string').findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqual(
        col.where().valueFieldStartsWith('').findAll(),
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
      await qEqualSet(
        col.where().filter().valueFieldStartsWith('').findAll(),
        {
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqual(col.where().valueFieldStartsWith('S').findAll(), []);
      await qEqualSet(
          col.where().filter().valueFieldStartsWith('S').findAll(), {});

      expect(() => col.where().valueFieldStartsWith(null), throwsA(anything));
      expect(() => col.where().filter().valueFieldStartsWith(null),
          throwsA(anything));
    });

    isarTest('.endsWith()', () async {
      await qEqualSet(
        col.where().filter().valueFieldEndsWith('4').findAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().valueFieldEndsWith('').findAll(),
        {
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
          col.where().filter().valueFieldEndsWith('8').findAll(), {});

      expect(() => col.where().filter().valueFieldEndsWith(null),
          throwsA(anything));
    });

    isarTest('.contains()', () async {
      await qEqualSet(
          col.where().filter().valueFieldContains('ing').findAll(), {
        StringModel.init('string 0'),
        StringModel.init('string 1'),
        StringModel.init('string 2'),
        StringModel.init('string 3'),
        StringModel.init('string 4'),
        StringModel.init('string 4'),
      });

      await qEqualSet(
        col.where().filter().valueFieldContains('').findAll(),
        {
          StringModel.init(''),
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
          col.where().filter().valueFieldContains('x').findAll(), {});

      expect(() => col.where().filter().valueFieldContains(null),
          throwsA(anything));
    });

    isarTest('.matches()', () async {
      await qEqualSet(
        col.where().filter().valueFieldMatches('*ng 4').findAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().valueFieldMatches('????????').findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 1'),
          StringModel.init('string 2'),
          StringModel.init('string 3'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().valueFieldMatches('').findAll(),
        {StringModel.init('')},
      );

      await qEqualSet(
          col.where().filter().valueFieldMatches('*4?').findAll(), {});
    });
  });
}
