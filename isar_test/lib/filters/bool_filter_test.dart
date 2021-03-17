import 'package:isar_test/isar_test_context.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/bool_model.dart';

void run(IsarTestContext context) {
  group('Bool filter', () {
    Isar isar;
    late IsarCollection<BoolModel> col;

    setUp(() async {
      isar = await context.openIsar();
      col = isar.boolModels;

      await isar.writeTxn((isar) async {
        await col.put(BoolModel()..field = false);
        await col.put(BoolModel()..field = true);
        await col.put(BoolModel()..field = false);
        await col.put(BoolModel()..field = null);
      });
    });

    context.test('.equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(true).findAll(),
        [BoolModel()..field = true],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(true).findAll(),
        [BoolModel()..field = true],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [BoolModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [BoolModel()..field = null],
      );
    });

    context.test('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(true).findAll(),
        [
          BoolModel()..field = null,
          BoolModel()..field = false,
          BoolModel()..field = false
        ],
      );

      await qEqual(
        col.where().fieldNotEqualTo(null).findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = true
        ],
      );
    });

    context.test('.isNull()', () async {
      await qEqualSet(
        col.where().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );

      await qEqualSet(
        col.where().filter().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );
    });

    context.test('.isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = true,
        ],
      );
    });
  });
}
