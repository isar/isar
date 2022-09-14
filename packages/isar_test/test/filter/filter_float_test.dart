import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_float_test.g.dart';

@collection
class FloatModel {
  FloatModel(this.field);

  Id? id;

  float? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && id == other.id && doubleEquals(field, other.field);
}

void main() {
  group('Float filter', () {
    late Isar isar;
    late IsarCollection<FloatModel> col;

    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objNInf;
    late FloatModel objInf;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      obj1 = FloatModel(1.1);
      obj2 = FloatModel(2.2);
      obj3 = FloatModel(3.3);
      objNInf = FloatModel(double.negativeInfinity);
      objInf = FloatModel(double.infinity);
      objNull = FloatModel(null);

      await isar.writeTxn(() async {
        await col.putAll([objInf, obj2, obj1, obj3, objNInf, objNull]);
      });
    });

    isarTest('.equalTo()', () async {
      await qEqual(col.filter().fieldEqualTo(2.2), [obj2]);
      await qEqual(col.filter().fieldEqualTo(2.1), []);
      await qEqual(col.filter().fieldEqualTo(2.1, epsilon: 0.2), [obj2]);
      await qEqual(col.filter().fieldEqualTo(2.3, epsilon: 0.2), [obj2]);
      await qEqual(col.filter().fieldEqualTo(null), [objNull]);
      await qEqual(col.filter().fieldEqualTo(double.infinity), [objInf]);
      await qEqual(
        col.filter().fieldEqualTo(double.negativeInfinity),
        [objNInf],
      );
    });

    isarTest('.greaterThan()', () async {
      await qEqual(
        col.filter().fieldGreaterThan(null),
        [objInf, obj2, obj1, obj3, objNInf],
      );
      await qEqual(
        col.filter().fieldGreaterThan(null, include: true),
        [objInf, obj2, obj1, obj3, objNInf, objNull],
      );
      await qEqual(
        col.filter().fieldGreaterThan(double.negativeInfinity),
        [objInf, obj2, obj1, obj3],
      );
      await qEqual(
        col.filter().fieldGreaterThan(double.negativeInfinity, include: true),
        [objInf, obj2, obj1, obj3, objNInf],
      );
      await qEqual(col.filter().fieldGreaterThan(2.2), [objInf, obj3]);
      await qEqual(
        col.filter().fieldGreaterThan(2.2, include: true),
        [objInf, obj2, obj3],
      );
      await qEqual(
        col.filter().fieldGreaterThan(2.3, epsilon: 0.2, include: true),
        [objInf, obj2, obj3],
      );
    });

    isarTest('.lessThan()', () async {
      await qEqual(col.filter().fieldLessThan(null), []);
      await qEqual(col.filter().fieldLessThan(null, include: true), [objNull]);
      await qEqual(
        col.filter().fieldLessThan(double.negativeInfinity),
        [objNull],
      );
      await qEqual(
        col.filter().fieldLessThan(double.negativeInfinity, include: true),
        [objNInf, objNull],
      );
      await qEqual(col.filter().fieldLessThan(1.1), [objNInf, objNull]);
      await qEqual(
        col.filter().fieldLessThan(1.1, include: true),
        [obj1, objNInf, objNull],
      );
      await qEqual(
        col.filter().fieldLessThan(1.2, epsilon: 0.2),
        [objNInf, objNull],
      );
      await qEqual(
        col.filter().fieldLessThan(1, include: true, epsilon: 0.2),
        [obj1, objNInf, objNull],
      );
    });

    isarTest('.between()', () async {
      await qEqual(col.filter().fieldBetween(null, null), [objNull]);
      await qEqual(col.filter().fieldBetween(1.1, 3.3), [obj2, obj1, obj3]);
      await qEqual(
        col.filter().fieldBetween(1.1, 3.3, includeLower: false),
        [obj2, obj3],
      );
      await qEqual(
        col.filter().fieldBetween(1.1, 3.3, includeUpper: false),
        [obj2, obj1],
      );
      await qEqual(
        col
            .filter()
            .fieldBetween(1.1, 3.3, includeLower: false, includeUpper: false),
        [obj2],
      );
      await qEqual(
        col.filter().fieldBetween(1.2, 3.2, epsilon: 0.2),
        [obj2, obj1, obj3],
      );
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().fieldIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(
        col.filter().fieldIsNotNull(),
        [objInf, obj2, obj1, obj3, objNInf],
      );
    });
  });
}
