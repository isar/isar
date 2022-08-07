import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_byte_test.g.dart';

@Collection()
class ByteModel {
  ByteModel(this.field);

  Id? id;

  @Index()
  byte field;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is ByteModel && other.id == id && other.field == field;
  }
}

void main() {
  group('Byte filter', () {
    late Isar isar;
    late IsarCollection<ByteModel> col;

    late ByteModel objMin;
    late ByteModel obj1;
    late ByteModel obj2;
    late ByteModel obj3;
    late ByteModel objMax;

    setUp(() async {
      isar = await openTempIsar([ByteModelSchema]);
      col = isar.byteModels;

      objMin = ByteModel(0);
      obj1 = ByteModel(1);
      obj2 = ByteModel(123);
      obj3 = ByteModel(1);
      objMax = ByteModel(255);

      await isar.writeTxn(() async {
        await col.putAll([objMin, obj1, obj2, obj3, objMax]);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('.equalTo()', () async {
      // where clauses
      await qEqual(col.where().fieldEqualTo(0).tFindAll(), [objMin]);
      await qEqual(col.where().fieldEqualTo(1).tFindAll(), [obj1, obj3]);

      // filters
      await qEqual(col.filter().fieldEqualTo(0).tFindAll(), [objMin]);
      await qEqual(col.filter().fieldEqualTo(1).tFindAll(), [obj1, obj3]);
    });

    isarTest('.notEqualTo()', () async {
      // where clauses
      await qEqual(
        col.where().fieldNotEqualTo(0).tFindAll(),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldNotEqualTo(1).tFindAll(),
        [objMin, obj2, objMax],
      );
    });

    isarTest('.greaterThan()', () async {
      // where clause
      await qEqual(
        col.where().fieldGreaterThan(0).tFindAll(),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldGreaterThan(0, include: true).tFindAll(),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(col.where().fieldGreaterThan(255).tFindAll(), []);
      await qEqual(
        col.where().fieldGreaterThan(255, include: true).tFindAll(),
        [objMax],
      );

      // filter
      await qEqual(
        col.filter().fieldGreaterThan(0).tFindAll(),
        [obj1, obj2, obj3, objMax],
      );
      await qEqual(
        col.filter().fieldGreaterThan(0, include: true).tFindAll(),
        [objMin, obj1, obj2, obj3, objMax],
      );
      await qEqual(col.filter().fieldGreaterThan(255).tFindAll(), []);
      await qEqual(
        col.filter().fieldGreaterThan(255, include: true).tFindAll(),
        [objMax],
      );
    });

    isarTest('.lessThan()', () async {
      // where clause
      await qEqual(
        col.where().fieldLessThan(255).tFindAll(),
        [objMin, obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldLessThan(255, include: true).tFindAll(),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(col.where().fieldLessThan(0).tFindAll(), []);
      await qEqual(
        col.where().fieldLessThan(0, include: true).tFindAll(),
        [objMin],
      );

      // filter
      await qEqual(
        col.filter().fieldLessThan(255).tFindAll(),
        [objMin, obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().fieldLessThan(255, include: true).tFindAll(),
        [objMin, obj1, obj2, obj3, objMax],
      );
      await qEqual(col.filter().fieldLessThan(0).tFindAll(), []);
      await qEqual(
        col.filter().fieldLessThan(0, include: true).tFindAll(),
        [objMin],
      );
    });

    isarTest('.between()', () async {
      // where clause
      await qEqual(
        col.where().fieldBetween(0, 255).tFindAll(),
        [objMin, obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldBetween(0, 255, includeLower: false).tFindAll(),
        [obj1, obj3, obj2, objMax],
      );
      await qEqual(
        col.where().fieldBetween(0, 255, includeUpper: false).tFindAll(),
        [objMin, obj1, obj3, obj2],
      );
      await qEqual(col.where().fieldBetween(255, 0).tFindAll(), []);
      await qEqual(col.where().fieldBetween(100, 110).tFindAll(), []);

      // filter
      await qEqual(
        col.filter().fieldBetween(0, 255).tFindAll(),
        [objMin, obj1, obj2, obj3, objMax],
      );
      await qEqual(
        col.filter().fieldBetween(0, 255, includeLower: false).tFindAll(),
        [obj1, obj2, obj3, objMax],
      );
      await qEqual(
        col.filter().fieldBetween(0, 255, includeUpper: false).tFindAll(),
        [objMin, obj1, obj2, obj3],
      );
      await qEqual(col.filter().fieldBetween(255, 0).tFindAll(), []);
      await qEqual(col.filter().fieldBetween(100, 110).tFindAll(), []);
    });
  });
}
