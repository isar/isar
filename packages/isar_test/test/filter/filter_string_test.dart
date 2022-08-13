import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_string_test.g.dart';

@Collection()
class StringModel {
  StringModel();

  StringModel.init(this.field);
  Id? id;

  String? field = '';

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is StringModel && field == other.field;
}

void main() {
  group('String filter', () {
    late Isar isar;
    late IsarCollection<StringModel> col;

    late StringModel objEmpty;
    late StringModel obj1;
    late StringModel obj2;
    late StringModel obj3;
    late StringModel obj4;
    late StringModel objNull;

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

    isarTest('.equalTo()', () async {
      await qEqual(
        col.filter().fieldEqualTo('string 2').tFindAll(),
        [StringModel.init('string 2')],
      );
      await qEqual(
        col.filter().fieldEqualTo(null).tFindAll(),
        [StringModel.init(null)],
      );
      await qEqual(
        col.filter().fieldEqualTo('string 5').tFindAll(),
        [],
      );
      await qEqual(
        col.filter().fieldEqualTo('').tFindAll(),
        [StringModel.init('')],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(
        col.filter().fieldIsNull().tFindAll(),
        [StringModel.init(null)],
      );
    });

    isarTest('.startsWith()', () async {
      await qEqualSet(
        col.filter().fieldStartsWith('string').tFindAll(),
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
        col.filter().fieldStartsWith('').tFindAll(),
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
      await qEqualSet(col.filter().fieldStartsWith('S').tFindAll(), {});
    });

    isarTest('.endsWith()', () async {
      await qEqualSet(
        col.filter().fieldEndsWith('4').tFindAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );
      await qEqualSet(
        col.filter().fieldEndsWith('').tFindAll(),
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
      await qEqualSet(col.filter().fieldEndsWith('8').tFindAll(), {});
    });

    isarTest('.contains()', () async {
      await qEqualSet(col.filter().fieldContains('ing').tFindAll(), {
        StringModel.init('string 0'),
        StringModel.init('string 1'),
        StringModel.init('string 2'),
        StringModel.init('string 3'),
        StringModel.init('string 4'),
        StringModel.init('string 4'),
      });
      await qEqualSet(
        col.filter().fieldContains('').tFindAll(),
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
        col.filter().fieldMatches('*ng 4').tFindAll(),
        {
          StringModel.init('string 4'),
          StringModel.init('string 4'),
        },
      );
      await qEqualSet(
        col.filter().fieldMatches('????????').tFindAll(),
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
        col.filter().fieldMatches('').tFindAll(),
        {StringModel.init('')},
      );

      await qEqualSet(col.filter().fieldMatches('*4?').tFindAll(), {});
    });
  });
}
