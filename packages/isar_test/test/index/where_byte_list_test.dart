import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'where_byte_list_test.g.dart';

@Collection()
class ByteModel {
  ByteModel(this.list) : hashList = list;

  Id? id;

  @Index(type: IndexType.value)
  List<byte>? list;

  @Index(type: IndexType.hash)
  List<byte>? hashList;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is ByteModel &&
        other.id == id &&
        listEquals(list, other.list) &&
        listEquals(hashList, other.hashList);
  }
}

void main() {
  group('Where byte list', () {
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
      await qEqualSet(
        col.where().listElementEqualTo(0).tFindAll(),
        [obj2, obj4],
      );
      await qEqualSet(col.where().listElementEqualTo(1).tFindAll(), [obj3]);
      await qEqualSet(
        col.where().listElementEqualTo(55).tFindAll(),
        [],
      );
    });

    isarTest('.elementNotEqualTo()', () async {
      await qEqualSet(
        col.where().listElementNotEqualTo(123).tFindAll(),
        [obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementNotEqualTo(0).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        col.where().listElementGreaterThan(123).tFindAll(),
        [obj2, obj4],
      );
      await qEqualSet(
        col.where().listElementGreaterThan(123, include: true).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementGreaterThan(255).tFindAll(),
        [],
      );
    });

    isarTest('.elementLessThan()', () async {
      await qEqualSet(
        col.where().listElementLessThan(123).tFindAll(),
        [obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementLessThan(123, include: true).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(col.where().listElementLessThan(0).tFindAll(), []);
    });

    isarTest('.elementBetween()', () async {
      await qEqualSet(
        col.where().listElementBetween(123, 255).tFindAll(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col
            .where()
            .listElementBetween(123, 255, includeLower: false)
            .tFindAll(),
        [obj2, obj4],
      );
      await qEqualSet(
        col
            .where()
            .listElementBetween(123, 255, includeUpper: false)
            .tFindAll(),
        [obj1, obj3],
      );
      await qEqualSet(col.where().listElementBetween(50, 100).tFindAll(), []);
    });

    isarTest('.equalTo()', () async {
      await qEqualSet(col.where().hashListEqualTo(null).tFindAll(), [objNull]);
      await qEqualSet(col.where().hashListEqualTo([]).tFindAll(), [objEmpty]);
      await qEqualSet(
        col.where().hashListEqualTo([0, 255]).tFindAll(),
        [obj2, obj4],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqualSet(
        col.where().hashListNotEqualTo([]).tFindAll(),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([0, 255]).tFindAll(),
        [objEmpty, obj1, obj3, objNull],
      );
    });

    isarTest('.isNull()', () async {
      await qEqualSet(col.where().hashListIsNull().tFindAll(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        col.where().hashListIsNotNull().tFindAll(),
        [objEmpty, obj1, obj2, obj3, obj4],
      );
    });
  });
}
