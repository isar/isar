import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_float_list_test.g.dart';

@collection
class FloatModel {
  FloatModel(this.id, this.list);

  final int id;

  List<float?>? list;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel &&
      id == other.id &&
      doubleListEquals(other.list, list);
}

void main() {
  group('Float list filter', () {
    late Isar isar;
    late IsarCollection<int, FloatModel> col;

    late FloatModel objEmpty;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objNull;

    setUp(() {
      isar = openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      objEmpty = FloatModel(0, []);
      obj1 = FloatModel(1, [1.1, 3.3]);
      obj2 = FloatModel(2, [null]);
      obj3 = FloatModel(3, [null, -1000]);
      objNull = FloatModel(4, null);

      isar.writeTxn((isar) {
        col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    isarTest('.elementEqualTo()', () {
      expect(col.where().listElementEqualTo(1.1).findAll(), [obj1]);
      expect(col.where().listElementEqualTo(4).findAll(), isEmpty);
      expect(col.where().listElementEqualTo(null).findAll(), [obj2, obj3]);
    });

    isarTest('.elementGreaterThan()', () {
      expect(col.where().listElementGreaterThan(3.3).findAll(), isEmpty);
      expect(
        col.where().listElementGreaterThan(3.3, include: true).findAll(),
        [obj1],
      );
      expect(
        col
            .where()
            .listElementGreaterThan(3.4, include: true, epsilon: 0.2)
            .findAll(),
        [obj1],
      );
      expect(col.where().listElementGreaterThan(4).findAll(), isEmpty);
      expect(col.where().listElementGreaterThan(null).findAll(), [obj1, obj3]);
      expect(
        col.where().listElementGreaterThan(null, include: true).findAll(),
        [obj1, obj2, obj3],
      );
    });

    isarTest('.elementLessThan()', () {
      expect(col.where().listElementLessThan(1.1).findAll(), [obj2, obj3]);
      expect(
        col.where().listElementLessThan(1.1, include: true).findAll(),
        [obj1, obj2, obj3],
      );
      expect(
        col
            .where()
            .listElementLessThan(1, include: true, epsilon: 0.2)
            .findAll(),
        [obj1, obj2, obj3],
      );
      expect(col.where().listElementLessThan(null).findAll(), isEmpty);
      expect(
        col.where().listElementLessThan(null, include: true).findAll(),
        [obj2, obj3],
      );
    });

    isarTest('.anyBetween()', () {
      expect(col.where().listElementBetween(1, 5).findAll(), [obj1]);
      expect(
        col.where().listElementBetween(null, 1.1).findAll(),
        [obj1, obj2, obj3],
      );
      expect(
        col
            .where()
            .listElementBetween(null, 1.1, includeLower: false)
            .findAll(),
        [obj1, obj3],
      );
      expect(
        col
            .where()
            .listElementBetween(null, 1.1, includeUpper: false)
            .findAll(),
        [obj2, obj3],
      );
      expect(
        col
            .where()
            .listElementBetween(
              null,
              1.1,
              includeLower: false,
              includeUpper: false,
            )
            .findAll(),
        [obj3],
      );
      expect(col.where().listElementBetween(5, 10).findAll(), isEmpty);
      expect(
        col.where().listElementBetween(null, null).findAll(),
        [obj2, obj3],
      );
    });

    isarTest('.elementIsNull()', () {
      expect(col.where().listElementIsNull().findAll(), [obj2, obj3]);
    });

    isarTest('.elementIsNotNull()', () {
      expect(col.where().listElementIsNotNull().findAll(), [obj1, obj3]);
    });

    isarTest('.isNull()', () {
      expect(col.where().listIsNull().findAll(), [objNull]);
    });

    isarTest('.isNotNull()', () {
      expect(
        col.where().listIsNotNull().findAll(),
        [objEmpty, obj1, obj2, obj3],
      );
    });
  });
}
