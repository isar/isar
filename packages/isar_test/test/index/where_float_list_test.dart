import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'where_float_list_test.g.dart';

@collection
class FloatModel {
  FloatModel(this.list);
  Id? id;

  @Index(type: IndexType.value)
  List<float?>? list;

  @override
  String toString() {
    return '{id: $id, list: $list}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is FloatModel && doubleListEquals(other.list, list);
}

void main() {
  group('Where float list', () {
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

    isarTest('.elementGreaterThan()', () async {
      await qEqualSet(
        col.where().listElementGreaterThan(1.1),
        [obj1],
      );
      await qEqualSet(col.where().listElementGreaterThan(4), []);
    });

    isarTest('.elementLessThan()', () async {
      await qEqualSet(
        col.where().listElementLessThan(1.1),
        [obj2, obj3],
      );
      await qEqualSet(col.where().listElementLessThan(null), []);
    });

    isarTest('.anyBetween()', () async {
      await qEqualSet(col.where().listElementBetween(1, 5), [obj1]);
      await qEqualSet(col.where().listElementBetween(5, 10), []);
    });

    isarTest('.elementIsNull()', () async {
      await qEqualSet(
        col.where().listElementIsNull(),
        [obj2, obj3],
      );
    });

    isarTest('.elementIsNotNull()', () async {
      await qEqualSet(
        col.where().listElementIsNotNull(),
        [obj1, obj3],
      );
    });
  });
}
