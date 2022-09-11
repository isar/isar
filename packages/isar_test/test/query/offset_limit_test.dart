import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'offset_limit_test.g.dart';

@collection
class Model {
  Model(this.value);

  final Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  final String value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model && other.id == id && other.value == value;
}

void main() {
  group('Offset Limit', () {
    late Isar isar;
    late IsarCollection<Model> col;

    late List<Model> objects;
    late List<Model> sorted;
    late Model objA;
    late Model objA2;
    late Model objB;
    late Model objC;
    late Model objC2;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      objA = Model('A');
      objA2 = Model('A');
      objB = Model('B');
      objC = Model('C');
      objC2 = Model('C');
      objects = [objB, objA, objC, objA2, objC2];
      sorted = [objA, objA2, objB, objC, objC2];

      await isar.writeTxn(() async {
        await col.putAll(objects);
      });
    });

    isarTest('0 offset', () async {
      await qEqual(col.where().offset(0), objects);
      await qEqual(col.where().anyValue().offset(0), sorted);
      await qEqual(col.where().sortByValue().offset(0), sorted);
    });

    isarTest('big offset', () async {
      await qEqual(col.where().offset(99), []);
      await qEqual(col.where().anyValue().offset(99), []);
      await qEqual(col.where().sortByValue().offset(99), []);
    });

    isarTest('offset', () async {
      await qEqual(col.where().offset(2), objects.sublist(2));
      await qEqual(col.where().anyValue().offset(2), sorted.sublist(2));
      await qEqual(col.where().sortByValue().offset(2), sorted.sublist(2));
    });

    isarTest('0 limit', () async {
      await qEqual(col.where().limit(0), []);
      await qEqual(col.where().anyValue().limit(0), []);
      await qEqual(col.where().sortByValue().limit(0), []);
    });

    isarTest('big limit', () async {
      await qEqual(col.where().limit(999999), objects);
      await qEqual(col.where().anyValue().limit(999999), sorted);
      await qEqual(col.where().sortByValue().limit(999999), sorted);
    });

    isarTest('limit', () async {
      await qEqual(col.where().limit(3), objects.sublist(0, 3));
      await qEqual(col.where().anyValue().limit(3), sorted.sublist(0, 3));
      await qEqual(col.where().sortByValue().limit(3), sorted.sublist(0, 3));
    });

    isarTest('offset and limit', () async {
      await qEqual(col.where().offset(3).limit(1), objects.sublist(3, 4));
      await qEqual(
        col.where().anyValue().offset(3).limit(1),
        sorted.sublist(3, 4),
      );
      await qEqual(
        col.where().sortByValue().offset(3).limit(1),
        sorted.sublist(3, 4),
      );
    });

    isarTest('offset and big limit', () async {
      await qEqual(col.where().offset(3).limit(1000), objects.sublist(3));
      await qEqual(
        col.where().anyValue().offset(3).limit(1000),
        sorted.sublist(3),
      );
      await qEqual(
        col.where().sortByValue().offset(3).limit(1000),
        sorted.sublist(3),
      );
    });

    isarTest('big offset and limit', () async {
      await qEqual(col.where().offset(300).limit(5), []);
      await qEqual(col.where().anyValue().offset(300).limit(5), []);
      await qEqual(col.where().sortByValue().offset(300).limit(5), []);
    });
  });
}
