import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_int_test.g.dart';

@collection
class IntModel {
  IntModel(this.field);
  Id? id;

  @Index()
  short? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IntModel && other.field == field;
  }

  @override
  String toString() {
    return '$field';
  }
}

void main() {
  group('Where int', () {
    late Isar isar;
    late IsarCollection<IntModel> col;

    late IntModel obj0;
    late IntModel obj1;
    late IntModel obj2;
    late IntModel obj3;
    late IntModel objNull;

    setUp(() async {
      isar = await openTempIsar([IntModelSchema]);
      col = isar.intModels;

      objNull = IntModel(null);
      obj0 = IntModel(-1234);
      obj1 = IntModel(1);
      obj2 = IntModel(2);
      obj3 = IntModel(1);

      await isar.writeTxn(() async {
        await isar.intModels.putAll([obj0, obj1, obj2, obj3, objNull]);
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(col.where().fieldEqualTo(2), [obj2]);
      await qEqual(col.where().fieldEqualTo(null), [objNull]);
      await qEqual(col.where().fieldEqualTo(5), []);
    });

    isarTest('.notEqualTo()', () async {
      await qEqual(
        col.where().fieldNotEqualTo(1),
        [objNull, obj0, obj2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(null),
        [obj0, obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldNotEqualTo(5),
        [objNull, obj0, obj1, obj3, obj2],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqual(col.where().fieldGreaterThan(1), [obj2]);
      await qEqual(
        col.where().fieldGreaterThan(1, include: true),
        [obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldGreaterThan(null),
        [obj0, obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldGreaterThan(null, include: true),
        [objNull, obj0, obj1, obj3, obj2],
      );
      await qEqual(col.where().fieldGreaterThan(4), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().fieldLessThan(1), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null), []);
      await qEqual(
        col.where().fieldLessThan(null, include: true),
        [objNull],
      );
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 2),
        [obj1, obj3, obj2],
      );
      await qEqual(
        col.where().fieldBetween(1, 2, includeLower: false),
        [obj2],
      );
      await qEqual(
        col.where().fieldBetween(1, 2, includeUpper: false),
        [obj1, obj3],
      );
      await qEqual(
        col
            .where()
            .fieldBetween(1, 2, includeLower: false, includeUpper: false),
        [],
      );
      await qEqual(
        col.where().fieldBetween(null, 1),
        [objNull, obj0, obj1, obj3],
      );
      await qEqual(col.where().fieldBetween(5, 6), []);
    });

    isarTest('.isNull() / .isNotNull()', () async {
      await qEqual(col.where().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.where().fieldIsNotNull(),
        [obj0, obj1, obj3, obj2],
      );
    });
  });
}
