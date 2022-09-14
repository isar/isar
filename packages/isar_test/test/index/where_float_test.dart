import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_float_test.g.dart';

@collection
class FloatModel {
  FloatModel();
  Id? id;

  @Index()
  float? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && doubleEquals(field, other.field);

  @override
  String toString() {
    return '{id: $id, field: $field}';
  }
}

void main() {
  group('Where float', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel obj0;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objInf;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      obj0 = FloatModel()..field = 0;
      obj1 = FloatModel()..field = 1.1;
      obj2 = FloatModel()..field = 2.2;
      obj3 = FloatModel()..field = 3.3;
      objInf = FloatModel()..field = double.infinity;
      objNull = FloatModel()..field = null;

      await isar.writeTxn(() async {
        await col.putAll([objInf, obj0, obj2, obj1, obj3, objNull]);
      });
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.where().fieldGreaterThan(null),
        [obj0, obj1, obj2, obj3, objInf],
      );
      await qEqual(
        col.where().fieldGreaterThan(2.2),
        [obj3, objInf],
      );
      await qEqual(
        col.where().fieldGreaterThan(double.infinity),
        [],
      );
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.where().fieldLessThan(1.1), [objNull, obj0]);
      await qEqual(col.where().fieldLessThan(null), []);
    });

    isarTest('.between()', () async {
      await qEqual(
        col.where().fieldBetween(1, 3.5),
        [obj1, obj2, obj3],
      );
      await qEqual(col.where().fieldBetween(5, 6), []);
    });

    isarTest('.isNull()', () async {
      await qEqual(col.where().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(col.filter().fieldIsNull(), [objNull]);
    });
  });
}
