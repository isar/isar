import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_byte_list_test.g.dart';

@Collection()
class ByteModel {
  ByteModel(this.list);

  Id? id;

  List<byte>? list;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is ByteModel && other.id == id && listEquals(list, other.list);
  }
}

void main() {
  group('Byte list filter', () {
    late Isar isar;
    late IsarCollection<ByteModel> col;

    late ByteModel objEmpty;
    late ByteModel obj1;
    late ByteModel obj2;
    late ByteModel obj3;
    late ByteModel obj4;
    late ByteModel objNull;

    setUp(() async {
      isar = await openTempIsar([ByteModelSchema]);
      col = isar.byteModels;

      objEmpty = ByteModel([]);
      obj1 = ByteModel([123]);
      obj2 = ByteModel([0, 255]);
      obj3 = ByteModel([1, 123, 3]);
      obj4 = ByteModel([0, 255]);
      objNull = ByteModel(null);

      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, obj4, objNull]);
      });
    });

    isarTest('.elementEqualTo()', () async {
      await qEqual(
        col.filter().listElementEqualTo(0).tFindAll(),
        [obj2, obj4],
      );
      await qEqual(col.filter().listElementEqualTo(1).tFindAll(), [obj3]);
      await qEqual(col.filter().listElementEqualTo(55).tFindAll(), []);
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqual(
        col.filter().listElementGreaterThan(123).tFindAll(),
        [obj2, obj4],
      );
      await qEqual(
        col.filter().listElementGreaterThan(123, include: true).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(col.filter().listElementGreaterThan(255).tFindAll(), []);
    });

    isarTest('.elementLessThan()', () async {
      await qEqual(
        col.filter().listElementLessThan(123).tFindAll(),
        [obj2, obj3, obj4],
      );
      await qEqual(
        col.filter().listElementLessThan(123, include: true).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(col.filter().listElementLessThan(0).tFindAll(), []);
    });

    isarTest('.elementBetween()', () async {
      await qEqual(
        col.filter().listElementBetween(123, 255).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        col
            .filter()
            .listElementBetween(123, 255, includeLower: false)
            .tFindAll(),
        [obj2, obj4],
      );
      await qEqual(
        col
            .filter()
            .listElementBetween(123, 255, includeUpper: false)
            .tFindAll(),
        [obj1, obj3],
      );
      await qEqual(col.filter().listElementBetween(50, 100).tFindAll(), []);
    });

    isarTest('.isNull()', () async {
      await qEqual(
        col.where().filter().listIsNull().tFindAll(),
        [objNull],
      );
    });
  });
}
