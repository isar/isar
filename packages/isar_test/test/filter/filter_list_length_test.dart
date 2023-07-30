import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_list_length_test.g.dart';

@collection
class Model {
  Model({
    required this.id,
    required this.bools,
    required this.ints,
    required this.doubles,
    required this.strings,
  });

  final int id;

  final List<bool> bools;

  final List<int>? ints;

  final List<double?> doubles;

  final List<String?>? strings;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Model &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(bools, other.bools) &&
          listEquals(ints, other.ints) &&
          listEquals(doubles, other.doubles) &&
          listEquals(strings, other.strings);

  @override
  String toString() {
    return '''Model{id: $id, bools: $bools, ints: $ints, doubles: $doubles, strings: $strings}''';
  }
}

void main() {
  group('Filter list length', () {
    late Isar isar;
    late Model obj1;
    late Model obj2;
    late Model obj3;
    late Model obj4;
    late Model obj5;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

      obj1 = Model(
        id: 1,
        bools: [],
        ints: [1, 42, -128],
        doubles: [1.123, 4, 5.333, 1.22, 1.22, 1.22],
        strings: null,
      );
      obj2 = Model(
        id: 2,
        bools: [true, true, false],
        ints: [4],
        doubles: [null],
        strings: ['Foo', 'bar'],
      );
      obj3 = Model(
        id: 3,
        bools: [true],
        ints: [0, 123],
        doubles: [3.141592653, null, null],
        strings: ['a', 'b', 'c', 'd'],
      );
      obj4 = Model(
        id: 4,
        bools: [true, true, false, true],
        ints: [-1, 1],
        doubles: [4, 12.2, 12.43],
        strings: ['', 'abc', null],
      );
      obj5 = Model(
        id: 5,
        bools: [true, true, true, true, true, false],
        ints: [],
        doubles: [],
        strings: [null, null],
      );

      isar.write(
        (isar) => isar.models.putAll([obj1, obj2, obj3, obj4, obj5]),
      );
    });

    isarTest('.isEmpty()', () {
      expect(isar.models.where().boolsIsEmpty().findAll(), [obj1]);
      expect(isar.models.where().intsIsEmpty().findAll(), [obj5]);
      expect(isar.models.where().doublesIsEmpty().findAll(), [obj5]);
      expect(isar.models.where().stringsIsEmpty().findAll(), isEmpty);
    });

    isarTest('.isNotEmpty()', () {
      expect(
        isar.models.where().boolsIsNotEmpty().findAll(),
        [obj2, obj3, obj4, obj5],
      );
      expect(
        isar.models.where().intsIsNotEmpty().findAll(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        isar.models.where().doublesIsNotEmpty().findAll(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        isar.models.where().stringsIsNotEmpty().findAll(),
        [obj2, obj3, obj4, obj5],
      );
    });
  });
}
