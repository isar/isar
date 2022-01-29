import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'common.dart';
import 'package:test/test.dart';

part 'filter_string_test.g.dart';

@Collection()
class StringModel {
  @Id()
  int? id;

  @Index(type: IndexType.value)
  String? field = '';

  @Index(type: IndexType.hash)
  String? hashField = '';

  @Index(type: IndexType.value)
  List<String>? list;

  @Index(type: IndexType.hash)
  List<String>? hashList;

  @Index(type: IndexType.hashElements)
  List<String>? hashElementList;

  @override
  String toString() {
    return '{field: $field, hashField: $hashField, list: $list, hashList: $hashList, hashElementList: $hashElementList}';
  }

  StringModel();

  StringModel.init(String? value)
      : field = value,
        hashField = value;

  @override
  bool operator ==(other) {
    if (other is StringModel) {
      return field == other.field &&
          hashField == other.hashField &&
          listEquals(list, other.list) &&
          listEquals(hashList, other.hashList) &&
          listEquals(hashElementList, other.hashElementList);
    }
    return false;
  }
}

void main() {
  group('String filter', () {
    late Isar isar;
    late IsarCollection<StringModel> col;

    setUp(() async {
      isar = await openTempIsar([StringModelSchema]);
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
        col.where().fieldEqualTo('string 2').findAll(),
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
        col.where().fieldEqualTo(null).findAll(),
        [StringModel.init(null)],
      );

      await qEqual(
        col.where().hashFieldEqualTo('string 5').findAll(),
        [],
      );
      await qEqual(
        col.where().fieldEqualTo('string 5').findAll(),
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
        col.where().fieldEqualTo('').findAll(),
        [StringModel.init('')],
      );

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
        col.where().fieldIsNull().findAll(),
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
        col.where().fieldIsNotNull().findAll(),
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
        col.where().fieldNotEqualTo('string 4').findAll(),
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
        col.where().fieldStartsWith('string').findAll(),
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
        col.where().filter().fieldStartsWith('string').findAll(),
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
        col.where().fieldStartsWith('').findAll(),
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
        col.where().filter().fieldStartsWith('').findAll(),
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

      await qEqual(col.where().fieldStartsWith('S').findAll(), []);
      await qEqualSet(col.where().filter().fieldStartsWith('S').findAll(), {});
    });

    isarTest('.endsWith()', () async {
      await qEqualSet(
        col.where().filter().fieldEndsWith('4').findAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().fieldEndsWith('').findAll(),
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

      await qEqualSet(col.where().filter().fieldEndsWith('8').findAll(), {});
    });

    isarTest('.contains()', () async {
      await qEqualSet(col.where().filter().fieldContains('ing').findAll(), {
        StringModel.init('string 0'),
        StringModel.init('string 1'),
        StringModel.init('string 2'),
        StringModel.init('string 3'),
        StringModel.init('string 4'),
        StringModel.init('string 4'),
      });

      await qEqualSet(
        col.where().filter().fieldContains('').findAll(),
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

      await qEqualSet(col.where().filter().fieldContains('x').findAll(), {});
    });

    isarTest('.matches()', () async {
      await qEqualSet(
        col.where().filter().fieldMatches('*ng 4').findAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().fieldMatches('????????').findAll(),
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
        col.where().filter().fieldMatches('').findAll(),
        {StringModel.init('')},
      );

      await qEqualSet(col.where().filter().fieldMatches('*4?').findAll(), {});
    });
  });
}
