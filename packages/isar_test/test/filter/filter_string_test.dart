import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_string_test.g.dart';

@Collection()
class StringModel {
  StringModel();

  StringModel.init(String? value)
      : field = value,
        hashField = value;
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
    return '{field: $field, hashField: $hashField, list: $list, hashList: '
        '$hashList, hashElementList: $hashElementList}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
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

      await isar.writeTxn(() async {
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
        col.where().hashFieldEqualTo('string 2').tFindAll(),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.where().fieldEqualTo('string 2').tFindAll(),
        [StringModel.init('string 2')],
      );

      await qEqual(
        col.where().filter().hashFieldEqualTo('string 2').tFindAll(),
        [StringModel.init('string 2')],
      );

      await qEqual(
        col.where().hashFieldEqualTo(null).tFindAll(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().fieldEqualTo(null).tFindAll(),
        [StringModel.init(null)],
      );

      await qEqual(
        col.where().hashFieldEqualTo('string 5').tFindAll(),
        [],
      );
      await qEqual(
        col.where().fieldEqualTo('string 5').tFindAll(),
        [],
      );
      await qEqual(
        col.where().filter().hashFieldEqualTo('string 5').tFindAll(),
        [],
      );

      await qEqual(
        col.where().hashFieldEqualTo('').tFindAll(),
        [StringModel.init('')],
      );
      await qEqual(
        col.where().fieldEqualTo('').tFindAll(),
        [StringModel.init('')],
      );

      await qEqual(
        col.where().filter().hashFieldEqualTo('').tFindAll(),
        [StringModel.init('')],
      );
    });

    isarTest('isNull()', () async {
      await qEqual(
        col.where().hashFieldIsNull().tFindAll(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.where().fieldIsNull().tFindAll(),
        [StringModel.init(null)],
      );

      await qEqual(
        col.where().filter().hashFieldIsNull().tFindAll(),
        [StringModel.init(null)],
      );
    });

    isarTest('isNotNull()', () async {
      await qEqualSet(
        col.where().hashFieldIsNotNull().tFindAll(),
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
        col.where().fieldIsNotNull().tFindAll(),
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
        col.where().hashFieldNotEqualTo('string 4').tFindAll(),
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
        col.where().fieldNotEqualTo('string 4').tFindAll(),
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
        col.where().fieldStartsWith('string').tFindAll(),
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
        col.where().filter().fieldStartsWith('string').tFindAll(),
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
        col.where().fieldStartsWith('').tFindAll(),
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
        col.where().filter().fieldStartsWith('').tFindAll(),
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

      await qEqual(col.where().fieldStartsWith('S').tFindAll(), []);
      await qEqualSet(col.where().filter().fieldStartsWith('S').tFindAll(), {});
    });

    isarTest('.endsWith()', () async {
      await qEqualSet(
        col.where().filter().fieldEndsWith('4').tFindAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().fieldEndsWith('').tFindAll(),
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

      await qEqualSet(col.where().filter().fieldEndsWith('8').tFindAll(), {});
    });

    isarTest('.contains()', () async {
      await qEqualSet(col.where().filter().fieldContains('ing').tFindAll(), {
        StringModel.init('string 0'),
        StringModel.init('string 1'),
        StringModel.init('string 2'),
        StringModel.init('string 3'),
        StringModel.init('string 4'),
        StringModel.init('string 4'),
      });

      await qEqualSet(
        col.where().filter().fieldContains('').tFindAll(),
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

      await qEqualSet(col.where().filter().fieldContains('x').tFindAll(), {});
    });

    isarTestVm('.matches()', () async {
      await qEqualSet(
        col.where().filter().fieldMatches('*ng 4').tFindAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );

      await qEqualSet(
        col.where().filter().fieldMatches('????????').tFindAll(),
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
        col.where().filter().fieldMatches('').tFindAll(),
        {StringModel.init('')},
      );

      await qEqualSet(col.where().filter().fieldMatches('*4?').tFindAll(), {});
    });
  });
}
