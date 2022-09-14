import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_id_test.g.dart';

@collection
class IdModel {
  IdModel();

  Id? id;

  @override
  String toString() {
    return '{id: $id}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IdModel && other.id == id;
  }
}

void main() {
  group('Where Id', () {
    late Isar isar;
    late IsarCollection<IdModel> col;

    late IdModel obj0;
    late IdModel obj1;
    late IdModel obj2;
    late IdModel obj3;

    setUp(() async {
      isar = await openTempIsar([IdModelSchema]);
      col = isar.idModels;

      obj0 = IdModel()..id = 0;
      obj1 = IdModel()..id = 1;
      obj2 = IdModel()..id = 2;
      obj3 = IdModel()..id = 3;

      await isar.writeTxn(() async {
        await isar.idModels.putAll([obj0, obj2, obj3, obj1]);
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(col.where().idEqualTo(2), [obj2]);
      await qEqual(col.where().idEqualTo(5), []);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(col.where().idNotEqualTo(2), [obj0, obj1, obj3]);
      await qEqual(
        col.where().idNotEqualTo(5),
        [obj0, obj1, obj2, obj3],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqual(col.where().idGreaterThan(2), [obj3]);
      await qEqual(
        col.where().idGreaterThan(2, include: true),
        [obj2, obj3],
      );
      await qEqual(col.where().idGreaterThan(3), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().idLessThan(1), [obj0]);
      await qEqual(
        col.where().idLessThan(1, include: true),
        [obj0, obj1],
      );
      await qEqual(col.where().idLessThan(-1), []);
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().idBetween(1, 3),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.where().idBetween(1, 3, includeLower: false),
        [obj2, obj3],
      );
      await qEqual(
        col.where().idBetween(1, 3, includeUpper: false),
        [obj1, obj2],
      );
      await qEqual(
        col.where().idBetween(1, 3, includeLower: false, includeUpper: false),
        [obj2],
      );
      await qEqual(col.where().idBetween(5, 6), []);
    });
  });
}
