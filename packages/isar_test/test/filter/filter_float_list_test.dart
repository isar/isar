import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_float_list_test.g.dart';

@collection
class FloatModel {
  FloatModel(this.list);

  Id? id;

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
    late IsarCollection<FloatModel> col;

    late FloatModel objEmpty;
    late FloatModel obj1;
    late FloatModel obj2;
    late FloatModel obj3;
    late FloatModel objNull;

    setUp(() async {
      isar = await openTempIsar([FloatModelSchema]);
      col = isar.floatModels;

      objEmpty = FloatModel([]);
      obj1 = FloatModel([1.1, 3.3]);
      obj2 = FloatModel([null]);
      obj3 = FloatModel([null, -1000]);
      objNull = FloatModel(null);

      await isar.writeTxn(() async {
        await col.putAll([objEmpty, obj1, obj2, obj3, objNull]);
      });
    });

    isarTest('.elementEqualTo()', () async {
      await qEqual(col.filter().listElementEqualTo(1.1), [obj1]);
      await qEqual(col.filter().listElementEqualTo(4), []);
      await qEqual(col.filter().listElementEqualTo(null), [obj2, obj3]);
    });

    isarTest('.elementGreaterThan()', () async {
      await qEqual(col.filter().listElementGreaterThan(3.3), []);
      await qEqual(
        col.filter().listElementGreaterThan(3.3, include: true),
        [obj1],
      );
      await qEqual(
        col.filter().listElementGreaterThan(3.4, include: true, epsilon: 0.2),
        [obj1],
      );
      await qEqual(col.filter().listElementGreaterThan(4), []);
      await qEqual(col.filter().listElementGreaterThan(null), [obj1, obj3]);
      await qEqual(
        col.filter().listElementGreaterThan(null, include: true),
        [obj1, obj2, obj3],
      );
    });

    isarTest('.elementLessThan()', () async {
      await qEqual(col.filter().listElementLessThan(1.1), [obj2, obj3]);
      await qEqual(
        col.filter().listElementLessThan(1.1, include: true),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().listElementLessThan(1, include: true, epsilon: 0.2),
        [obj1, obj2, obj3],
      );
      await qEqual(col.filter().listElementLessThan(null), []);
      await qEqual(
        col.filter().listElementLessThan(null, include: true),
        [obj2, obj3],
      );
    });

    isarTest('.anyBetween()', () async {
      await qEqual(col.filter().listElementBetween(1, 5), [obj1]);
      await qEqual(
        col.filter().listElementBetween(null, 1.1),
        [obj1, obj2, obj3],
      );
      await qEqual(
        col.filter().listElementBetween(null, 1.1, includeLower: false),
        [obj1, obj3],
      );
      await qEqual(
        col.filter().listElementBetween(null, 1.1, includeUpper: false),
        [obj2, obj3],
      );
      await qEqual(
        col.filter().listElementBetween(
              null,
              1.1,
              includeLower: false,
              includeUpper: false,
            ),
        [obj3],
      );
      await qEqual(col.filter().listElementBetween(5, 10), []);
      await qEqual(col.filter().listElementBetween(null, null), [obj2, obj3]);
    });

    isarTest('.elementIsNull()', () async {
      await qEqual(col.filter().listElementIsNull(), [obj2, obj3]);
    });

    isarTest('.elementIsNotNull()', () async {
      await qEqual(col.filter().listElementIsNotNull(), [obj1, obj3]);
    });

    isarTest('.isNull()', () async {
      await qEqual(col.filter().listIsNull(), [objNull]);
    });

    isarTest('.isNotNull()', () async {
      await qEqual(col.filter().listIsNotNull(), [objEmpty, obj1, obj2, obj3]);
    });
  });
}
