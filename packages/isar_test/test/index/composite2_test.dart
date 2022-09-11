import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'composite2_test.g.dart';

@collection
class Model {
  Model(this.value1, this.value2);
  Id? id;

  @Index(
    composite: [CompositeIndex('value2')],
    unique: true,
  )
  int value1;

  double value2;

  @override
  String toString() {
    return '{id: $id, value1: $value1, value2: $value2}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return (other is Model) &&
        other.id == id &&
        other.value1 == value1 &&
        other.value2 == value2;
  }
}

void main() {
  group('Composite Index2', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      obj1 = Model(1, 1);
      obj2 = Model(1, 2);
      obj3 = Model(2, 1);
      obj4 = Model(2, 3);

      await isar.writeTxn(() async {
        await col.putAll([obj3, obj1, obj4, obj2]);
      });
    });

    isarTest('sorted by value1 value2', () async {
      await qEqual(
        col.where().anyValue1Value2(),
        [obj1, obj2, obj3, obj4],
      );
    });

    isarTest('getBy value1 sorted by value2', () async {
      await qEqual(
        col.where().value1GreaterThanAnyValue2(0),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(col.where().value1EqualToAnyValue2(1), [obj1, obj2]);
      await qEqual(col.where().value1EqualToAnyValue2(2), [obj3, obj4]);
    });

    isarTest('getBy value1 and value2', () async {
      await qEqual(
        col.where().value1EqualToValue2GreaterThan(1, 0),
        [obj1, obj2],
      );
      await qEqual(
        col.where().value1EqualToValue2GreaterThan(2, 0),
        [obj3, obj4],
      );
      await qEqual(col.where().value1EqualToValue2GreaterThan(2, 1), [obj4]);
    });
  });
}
