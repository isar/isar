import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_int_test.g.dart';

@collection
class IntModel {
  IntModel(this.field);

  Id? id;

  short? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return other is IntModel && id == other.id && other.field == field;
  }
}

void main() {
  group('Int filter', () {
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
      await qEqual(col.filter().fieldEqualTo(2), [obj2]);
      await qEqual(col.filter().fieldEqualTo(null), [objNull]);
      await qEqual(col.filter().fieldEqualTo(5), []);
    });

    isarTest('.greaterThan()', () async {
      await qEqual(col.filter().fieldGreaterThan(1), [obj2]);
      await qEqual(
        col.filter().fieldGreaterThan(1, include: true),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().fieldGreaterThan(null),
        [obj0, obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().fieldGreaterThan(null, include: true),
        [obj0, obj1, obj2, obj3, objNull],
      );
      await qEqual(col.filter().fieldGreaterThan(4), []);
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.filter().fieldLessThan(1), [obj0, objNull]);
      await qEqual(col.filter().fieldLessThan(null), []);
      await qEqual(col.filter().fieldLessThan(null, include: true), [objNull]);
    });

    isarTest('.between()', () async {
      await qEqual(col.filter().fieldBetween(1, 2), [obj1, obj2, obj3]);
      await qEqual(
        col.filter().fieldBetween(1, 2, includeLower: false),
        [obj2],
      );
      await qEqual(
        col.filter().fieldBetween(1, 2, includeUpper: false),
        [obj1, obj3],
      );
      await qEqual(
        col
            .filter()
            .fieldBetween(1, 2, includeLower: false, includeUpper: false),
        [],
      );
      await qEqual(
        col.filter().fieldBetween(null, 1),
        [obj0, obj1, obj3, objNull],
      );
      await qEqual(col.filter().fieldBetween(5, 6), []);
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(col.filter().fieldIsNotNull(), [obj0, obj1, obj2, obj3]);
    });
  });
}
