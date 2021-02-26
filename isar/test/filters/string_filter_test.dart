import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/string_model.dart';

void main() {
  group('String filter', () {
    Isar isar;
    late IsarCollection<StringModel> col;

    setUp(() async {
      setupIsar();

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

    test('isNotEqualTo()', () async {
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

    test('in()', () async {
      await qEqualSet(
        col.where().hashFieldIn(['string 4', 'string 0']).findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );
      await qEqualSet(
        col.where().valueFieldIn(['string 4', 'string 0']).findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );
      await qEqualSet(
        col.where().wordsFieldWordIn(['4', '0']).findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );
      await qEqualSet(
        col.where().filter().valueFieldIn(['string 4', 'string 0']).findAll(),
        {
          StringModel.init('string 0'),
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().hashFieldIn(['', null, 'String 0']).findAll(),
        {
          StringModel.init(''),
          StringModel.init(null),
        },
      );
      await qEqualSet(
        col.where().valueFieldIn(['', null, 'String 0']).findAll(),
        {
          StringModel.init(''),
          StringModel.init(null),
        },
      );
      await qEqualSet(
        col.where().filter().valueFieldIn([null, '', 'String 0']).findAll(),
        {
          StringModel.init(''),
          StringModel.init(null),
        },
      );

      expect(() => col.where().hashFieldIn([]), throwsA(anything));
      expect(() => col.where().valueFieldIn([]), throwsA(anything));
      expect(() => col.where().wordsFieldWordIn([]), throwsA(anything));
      expect(() => col.where().filter().hashFieldIn([]), throwsA(anything));
    });

    test('.startsWith()', () async {
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

    test('.endsWith()', () async {
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

    test('.contains()', () async {
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

    test('.matches()', () async {
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
