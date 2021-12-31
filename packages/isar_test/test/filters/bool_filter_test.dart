import 'package:isar/isar.dart';
import 'package:isar_test/bool_model.dart';
import 'package:isar_test/common.dart';
import 'package:test/test.dart';

void main() {
  group('Bool filter', () {
    late Isar isar;
    late IsarCollection<BoolModel> col;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema]);
      col = isar.boolModels;

      await isar.writeTxn((isar) async {
        await col.put(BoolModel()..field = false);
        await col.put(BoolModel()..field = true);
        await col.put(BoolModel()..field = false);
        await col.put(BoolModel()..field = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.equalTo()', () async {
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

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(true).findAll(),
        [
          BoolModel()..field = null,
          BoolModel()..field = false,
          BoolModel()..field = false
        ],
      );

      await qEqual(
        col.where(sort: Sort.desc).fieldNotEqualTo(true).findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = null,
        ],
      );

      await qEqual(
        col.where(sort: Sort.desc).fieldNotEqualTo(null).findAll(),
        [
          BoolModel()..field = true,
          BoolModel()..field = false,
          BoolModel()..field = false,
        ],
      );
    });

    isarTest('.isNull()', () async {
      await qEqualSet(
        col.where().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );

      await qEqualSet(
        col.where().filter().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull().findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = true,
        ],
      );

      await qEqual(
        col.where(sort: Sort.desc).fieldIsNotNull().findAll(),
        [
          BoolModel()..field = true,
          BoolModel()..field = false,
          BoolModel()..field = false,
        ],
      );
    });
  });

  /*group('Bool list filter', () {
    late Isar isar;
    late IsarCollection<BoolModel> col;

    setUp(() async {
      isar = await openTempIsar([BoolModelSchema]);
      col = isar.boolModels;

      await isar.writeTxn((isar) async {
        await col.put(BoolModel()..list = []);
        await col.put(BoolModel()..list = [true]);
        await col.put(BoolModel()..list = [null, false]);
        await col.put(BoolModel()..list = [true, false, true]);
        await col.put(BoolModel()..list = null);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.anyEqualTo()', () async {
      await qEqual(
        col.where().listAnyEqualTo(true).findAll(),
        [
          BoolModel()..list = [true]
        ],
      );
      await qEqual(
        col.where().filter().listAnyEqualTo(true).findAll(),
        [
          BoolModel()..list = [true, false, true]
        ],
      );

      await qEqual(
        col.where().fieldEqualTo(null).findAll(),
        [
          BoolModel()..list = [null, false]
        ],
      );
      await qEqual(
        col.where().filter().fieldEqualTo(null).findAll(),
        [
          BoolModel()..list = [null, false]
        ],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().listAnyNotEqualTo(true).findAll(),
        [
          BoolModel()..list = [null, false]
        ],
      );

      /*await qEqual(
        col.where().lis(null).findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = true
        ],
      );*/
    });

    isarTest('field.isNull()', () async {
      await qEqualSet(
        col.where().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );

      await qEqualSet(
        col.where().filter().fieldIsNull().findAll(),
        [BoolModel()..field = null],
      );
    });

    isarTest('field.isNotNull()', () async {
      await qEqualSet(
        col.where().fieldIsNotNull().findAll(),
        [
          BoolModel()..field = false,
          BoolModel()..field = false,
          BoolModel()..field = true,
        ],
      );
    });
  });*/
}
