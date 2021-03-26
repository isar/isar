import 'package:isar_test/isar_test_context.dart';
import 'package:test/test.dart';

import '../common.dart';
import '../isar.g.dart';
import '../models/int_model.dart';

void run(IsarTestContext context) {
  group('Int filter', () {
    late Isar isar;
    late IsarCollection<IntModel> col;

    setUp(() async {
      isar = await context.openIsar();
      col = isar.intModels;

      var obj;
      await isar.writeTxn((isar) async {
        for (var i = 0; i < 5; i++) {
          obj = IntModel()..field = i;
          await col.put(obj);
        }
        await col.put(IntModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    context.test('.equalTo()', () async {
      await qEqual(
        col.where().fieldEqualTo(2).findAll(),
        [IntModel()..field = 2],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(2).findAll(),
        [IntModel()..field = 2],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [IntModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [IntModel()..field = null],
      );

      await qEqual(
        col.where().fieldEqualTo(5).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(5).findAll(),
        [],
      );
    });

    context.test('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(3).findAll(),
        [IntModel()..field = 4],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(3).findAll(),
        [IntModel()..field = 4],
      );

      await qEqual(
        col.where().fieldGreaterThan(3, include: true).findAll(),
        [IntModel()..field = 3, IntModel()..field = 4],
      );
      await qEqualSet(
        col.where().filter().fieldGreaterThan(3, include: true).findAll(),
        {IntModel()..field = 3, IntModel()..field = 4},
      );

      await qEqual(
        col.where().fieldGreaterThan(null).findAll(),
        [
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = 4,
        ],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(null).findAll(),
        [
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = 4,
        ],
      );

      await qEqual(
        col.where().fieldGreaterThan(4).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldGreaterThan(4).findAll(),
        [],
      );
    });

    context.test('.lessThan()', () async {
      await qEqual(
        col.where().fieldLessThan(1).findAll(),
        [IntModel()..field = null, IntModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1).findAll(),
        {IntModel()..field = null, IntModel()..field = 0},
      );

      await qEqual(
        col.where().fieldLessThan(1, include: true).findAll(),
        [
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1
        ],
      );
      await qEqualSet(
        col.where().filter().fieldLessThan(1, include: true).findAll(),
        {
          IntModel()..field = null,
          IntModel()..field = 0,
          IntModel()..field = 1
        },
      );
    });

    context.test('.between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3).findAll(),
        [IntModel()..field = 1, IntModel()..field = 2, IntModel()..field = 3],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3).findAll(),
        {IntModel()..field = 1, IntModel()..field = 2, IntModel()..field = 3},
      );

      await qEqual(
        col.where().fieldBetween(null, 0).findAll(),
        [IntModel()..field = null, IntModel()..field = 0],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(null, 0).findAll(),
        {IntModel()..field = null, IntModel()..field = 0},
      );

      await qEqual(
        col.where().fieldBetween(1, 3, includeLower: false).findAll(),
        [IntModel()..field = 2, IntModel()..field = 3],
      );
      await qEqualSet(
          col
              .where()
              .filter()
              .fieldBetween(1, 3, includeLower: false)
              .findAll(),
          {IntModel()..field = 2, IntModel()..field = 3});

      await qEqual(
        col.where().fieldBetween(1, 3, includeUpper: false).findAll(),
        [IntModel()..field = 1, IntModel()..field = 2],
      );
      await qEqualSet(
        col.where().filter().fieldBetween(1, 3, includeUpper: false).findAll(),
        {IntModel()..field = 1, IntModel()..field = 2},
      );

      await qEqual(
        col
            .where()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [IntModel()..field = 2],
      );
      await qEqual(
        col
            .where()
            .filter()
            .fieldBetween(1, 3, includeLower: false, includeUpper: false)
            .findAll(),
        [IntModel()..field = 2],
      );

      await qEqual(
        col.where().fieldBetween(5, 6).findAll(),
        [],
      );
      await qEqual(
        col.where().filter().fieldBetween(5, 6).findAll(),
        [],
      );
    });

    context.test('.in()', () async {
      /*await qEqual(
        col.where().fieldIn([null, 2, 3]).findAll(),
        [
          IntModel()..field = null,
          IntModel()..field = 2,
          IntModel()..field = 3,
        ],
      );*/
      await qEqual(
        col.where().filter().fieldIn([null, 2, 3]).findAll(),
        [
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = null,
        ],
      );

      expect(() => col.where().fieldIn([]), throwsA(anything));
      expect(() => col.where().filter().fieldIn([]), throwsA(anything));
    });

    context.test('.isNull()', () async {
      await qEqual(
        col.where().fieldIsNull().findAll(),
        [IntModel()..field = null],
      );
      await qEqual(
        col.where().filter().fieldIsNull().findAll(),
        [IntModel()..field = null],
      );
    });

    context.test('.isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        {
          IntModel()..field = 0,
          IntModel()..field = 1,
          IntModel()..field = 2,
          IntModel()..field = 3,
          IntModel()..field = 4,
        },
      );
    });
  });
}
