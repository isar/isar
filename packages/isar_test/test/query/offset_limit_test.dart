import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'offset_limit_test.g.dart';

@collection
class Model {
  Model(this.id, this.value);

  final int id;

  final String value;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      other is Model && other.id == id && other.value == value;
}

void main() {
  group('Offset Limit', () {
    late Isar isar;
    late IsarCollection<int, Model> col;

    late Model objA;
    late Model objA2;
    late Model objB;
    late Model objC;
    late Model objC2;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      objA = Model(0, 'A');
      objA2 = Model(1, 'A');
      objB = Model(2, 'B');
      objC = Model(3, 'C');
      objC2 = Model(4, 'C');

      isar.write((isar) {
        col.putAll([objA, objA2, objB, objC, objC2]);
      });
    });

    isarTest('0 offset', () {
      expect(col.where().findAll(offset: 0), [objA, objA2, objB, objC, objC2]);
    });

    isarTest('big offset', () {
      expect(col.where().findAll(offset: 99), isEmpty);
    });

    isarTest('offset', () {
      expect(col.where().findAll(offset: 2), [objB, objC, objC2]);
    });

    isarTest('0 limit', () {
      expect(() => col.where().findAll(limit: 0), throwsArgumentError);
    });

    isarTest('big limit', () {
      expect(
        col.where().findAll(limit: 999999),
        [objA, objA2, objB, objC, objC2],
      );
    });

    isarTest('limit', () {
      expect(col.where().findAll(limit: 3), [objA, objA2, objB]);
    });

    isarTest('offset and limit', () {
      expect(col.where().findAll(offset: 3, limit: 1), [objC]);
      expect(col.where().findAll(offset: 3, limit: 2), [objC, objC2]);
    });

    isarTest('offset and big limit', () {
      expect(col.where().findAll(offset: 2, limit: 1000), [objB, objC, objC2]);
    });

    isarTest('big offset and limit', () {
      expect(col.where().findAll(offset: 300, limit: 5), isEmpty);
    });
  });
}
