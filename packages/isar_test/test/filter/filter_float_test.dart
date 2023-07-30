import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_float_test.g.dart';

@collection
class FloatModel {
  FloatModel(this.id, this.field);

  final int id;

  float? field = 0;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && id == other.id && doubleEquals(field, other.field);
}

void main() {
  group('Float filter', () {
    late Isar isar;
    late IsarCollection<int, FloatModel> col;

    late FloatModel obj2;
    late FloatModel obj1;
    late FloatModel obj3;
    late FloatModel objNInf;
    late FloatModel objInf;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      objInf = FloatModel(0, double.infinity);
      obj1 = FloatModel(1, 2.2);
      obj2 = FloatModel(2, 1.1);
      obj3 = FloatModel(3, 3.3);
      objNInf = FloatModel(4, double.negativeInfinity);
      objNull = FloatModel(5, null);

      isar.write((isar) {
        col.putAll([objInf, obj1, obj2, obj3, objNInf, objNull]);
      });
    });

    isarTest('.equalTo()', () {
      expect(col.where().fieldEqualTo(2.2).findAll(), [obj1]);
      expect(col.where().fieldEqualTo(2.1).findAll(), isEmpty);
      expect(col.where().fieldEqualTo(2.1, epsilon: 0.2).findAll(), [obj1]);
      expect(col.where().fieldEqualTo(2.3, epsilon: 0.2).findAll(), [obj1]);
      expect(col.where().fieldEqualTo(null).findAll(), [objNull]);
      expect(col.where().fieldEqualTo(double.infinity).findAll(), [objInf]);
      expect(
        col.where().fieldEqualTo(double.negativeInfinity).findAll(),
        [objNInf],
      );
    });

    isarTest('.greaterThan()', () {
      expect(
        col.where().fieldGreaterThan(null).findAll(),
        [objInf, obj1, obj2, obj3, objNInf],
      );
      expect(
        col.where().fieldGreaterThan(double.negativeInfinity).findAll(),
        [objInf, obj1, obj2, obj3],
      );
      expect(col.where().fieldGreaterThan(2.2).findAll(), [objInf, obj3]);
    });

    isarTest('.greaterThanOrEqualTo()', () {
      expect(
        col.where().fieldGreaterThanOrEqualTo(null).findAll(),
        [objInf, obj1, obj2, obj3, objNInf, objNull],
      );
      expect(
        col
            .where()
            .fieldGreaterThanOrEqualTo(double.negativeInfinity)
            .findAll(),
        [objInf, obj1, obj2, obj3, objNInf],
      );
      expect(
        col.where().fieldGreaterThanOrEqualTo(2.2).findAll(),
        [objInf, obj1, obj3],
      );
      expect(
        col.where().fieldGreaterThanOrEqualTo(2.3, epsilon: 0.2).findAll(),
        [objInf, obj1, obj3],
      );
    });

    isarTest('.lessThan()', () {
      expect(col.where().fieldLessThan(null).findAll(), isEmpty);
      expect(
        col.where().fieldLessThan(double.negativeInfinity).findAll(),
        [objNull],
      );
      expect(col.where().fieldLessThan(1.1).findAll(), [objNInf, objNull]);
      expect(
        col.where().fieldLessThan(1.2, epsilon: 0.2).findAll(),
        [objNInf, objNull],
      );
    });

    isarTest('.lessThanOrEqualTo()', () {
      expect(
        col.where().fieldLessThanOrEqualTo(null).findAll(),
        [objNull],
      );
      expect(
        col.where().fieldLessThanOrEqualTo(double.negativeInfinity).findAll(),
        [objNInf, objNull],
      );
      expect(
        col.where().fieldLessThanOrEqualTo(1.1).findAll(),
        [obj2, objNInf, objNull],
      );
      expect(
        col.where().fieldLessThanOrEqualTo(1, epsilon: 0.2).findAll(),
        [obj2, objNInf, objNull],
      );
    });

    isarTest('.between()', () {
      expect(col.where().fieldBetween(null, null).findAll(), [objNull]);
      expect(col.where().fieldBetween(1.1, 3.3).findAll(), [obj1, obj2, obj3]);
      expect(
        col.where().fieldBetween(1.2, 3.2, epsilon: 0.2).findAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('.isNull()', () {
      expect(col.where().fieldIsNull().findAll(), [objNull]);
    });

    isarTest('.isNotNull()', () {
      expect(
        col.where().fieldIsNotNull().findAll(),
        [objInf, obj1, obj2, obj3, objNInf],
      );
    });
  });
}
