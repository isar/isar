import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_byte_list_test.g.dart';

@collection
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
        col.where().listElementEqualTo(0),
        [obj2, obj4],
      );
      await qEqualSet(col.where().listElementEqualTo(1), [obj3]);
      await qEqualSet(
        col.where().listElementEqualTo(55),
        [],
      );
    });

    isarTest('.elementNotEqualTo()', () async {
      await qEqualSet(
        col.where().listElementNotEqualTo(123),
        [obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementNotEqualTo(0),
        [obj1, obj2, obj3, obj4],
      );
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        col.where().listElementGreaterThan(123),
        [obj2, obj4],
      );
      await qEqualSet(
        col.where().listElementGreaterThan(123, include: true),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementGreaterThan(255),
        [],
      );
    });

    isarTest('.elementLessThan()', () async {
      await qEqualSet(
        col.where().listElementLessThan(123),
        [obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementLessThan(123, include: true),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(col.where().listElementLessThan(0), []);
    });

    isarTest('.elementBetween()', () async {
      await qEqualSet(
        col.where().listElementBetween(123, 255),
        [obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().listElementBetween(123, 255, includeLower: false),
        [obj2, obj4],
      );
      await qEqualSet(
        col.where().listElementBetween(123, 255, includeUpper: false),
        [obj1, obj3],
      );
      await qEqualSet(col.where().listElementBetween(50, 100), []);
    });

    isarTest('.equalTo()', () async {
      await qEqualSet(col.where().hashListEqualTo(null), [objNull]);
      await qEqualSet(col.where().hashListEqualTo([]), [objEmpty]);
      await qEqualSet(
        col.where().hashListEqualTo([0, 255]),
        [obj2, obj4],
      );
    });

    isarTest('.notEqualTo()', () async {
      await qEqualSet(
        col.where().hashListNotEqualTo([]),
        [objNull, obj1, obj2, obj3, obj4],
      );
      await qEqualSet(
        col.where().hashListNotEqualTo([0, 255]),
        [objEmpty, obj1, obj3, objNull],
      );
    });

    isarTest('.isNull()', () async {
      await qEqualSet(col.where().hashListIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqualSet(
        col.where().hashListIsNotNull(),
        [objEmpty, obj1, obj2, obj3, obj4],
      );
    });
  });
}
