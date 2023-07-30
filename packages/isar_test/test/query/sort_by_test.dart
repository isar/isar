import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'sort_by_test.g.dart';

@collection
class Model {
  Model(this.id, this.name, this.active);

  final int id;

  final String name;

  final bool active;

  @override
  bool operator ==(other) =>
      other is Model &&
      other.name == name &&
      other.id == id &&
      other.active == active;
}

void main() {
  group('Sort By', () {
    late IsarCollection<int, Model> col;

    late Model modelA1;
    late Model modelA2;
    late Model modelB1;
    late Model modelB2;
    late Model modelC1;
    late Model modelC2;

    setUp(() async {
      final isar = await openTempIsar([ModelSchema]);
      col = isar.models;

      modelA1 = Model(100, 'a', true);
      modelA2 = Model(200, 'a', true);
      modelB1 = Model(10, 'b', true);
      modelB2 = Model(20, 'b', false);
      modelC1 = Model(1, 'c', false);
      modelC2 = Model(2, 'c', true);

      isar.write(
        (isar) => isar.models
            .putAll([modelA1, modelA2, modelB1, modelB2, modelC1, modelC2]),
      );
    });

    isarTest('.sortBy()', () {
      expect(
        col.where().sortByName().findAll(),
        [modelA1, modelA2, modelB1, modelB2, modelC1, modelC2],
      );

      expect(
        col.where().nameBetween('b', 'c').sortByName().findAll(),
        [modelB1, modelB2, modelC1, modelC2],
      );

      expect(
        col.where().sortByName().thenByNameDesc().findAll(),
        [modelA1, modelA2, modelB1, modelB2, modelC1, modelC2],
      );

      expect(
        col.where().sortByActive().findAll(),
        [modelC1, modelB2, modelC2, modelB1, modelA1, modelA2],
      );

      expect(
        col.where().sortById().findAll(),
        [modelC1, modelC2, modelB1, modelB2, modelA1, modelA2],
      );

      expect(
        col.where().findAll(),
        [modelC1, modelC2, modelB1, modelB2, modelA1, modelA2],
      );
    });

    isarTest('.sortByDesc()', () {
      expect(
        col.where().sortByNameDesc().findAll(),
        [modelC1, modelC2, modelB1, modelB2, modelA1, modelA2],
      );

      expect(
        col.where().nameBetween('b', 'c').sortByNameDesc().findAll(),
        [modelC1, modelC2, modelB1, modelB2],
      );

      expect(
        col.where().sortByNameDesc().thenByName().findAll(),
        [modelC1, modelC2, modelB1, modelB2, modelA1, modelA2],
      );

      expect(
        col.where().sortByActiveDesc().findAll(),
        [modelC2, modelB1, modelA1, modelA2, modelC1, modelB2],
      );

      expect(
        col.where().sortByIdDesc().findAll(),
        [modelA2, modelA1, modelB2, modelB1, modelC2, modelC1],
      );

      expect(
        col.where().findAll(),
        [modelC1, modelC2, modelB1, modelB2, modelA1, modelA2],
      );
    });

    isarTest('.sortBy().thenBy()', () {
      expect(
        col.where().sortByName().thenById().findAll(),
        [modelA1, modelA2, modelB1, modelB2, modelC1, modelC2],
      );

      expect(
        col.where().sortByActive().thenByName().findAll(),
        [modelB2, modelC1, modelA1, modelA2, modelB1, modelC2],
      );

      expect(
        col.where().activeEqualTo(true).sortByName().thenById().findAll(),
        [modelA1, modelA2, modelB1, modelC2],
      );
    });

    isarTest('.sortBy().thenByDesc()', () {
      expect(
        col.where().sortByName().thenByIdDesc().findAll(),
        [modelA2, modelA1, modelB2, modelB1, modelC2, modelC1],
      );

      expect(
        col.where().sortByActive().thenByNameDesc().findAll(),
        [modelC1, modelB2, modelC2, modelB1, modelA1, modelA2],
      );

      expect(
        col.where().activeEqualTo(true).sortByName().thenByIdDesc().findAll(),
        [modelA2, modelA1, modelB1, modelC2],
      );
    });

    isarTest('.sortBy().thenBy().thenBy()', () {
      expect(
        col.where().sortByActive().thenByName().thenByIdDesc().findAll(),
        [modelB2, modelC1, modelA2, modelA1, modelB1, modelC2],
      );
    });
  });
}
