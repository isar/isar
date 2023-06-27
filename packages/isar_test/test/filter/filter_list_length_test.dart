import 'dart:math';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'filter_list_length_test.g.dart';

@collection
class Model {
  Model({
    required this.bools,
    required this.ints,
    required this.doubles,
    required this.strings,
  });

  int id = Random().nextInt(99999);

  final List<bool> bools;

  @Index()
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

    setUp(() {
      isar = openTempIsar([ModelSchema]);

      obj1 = Model(
        bools: [],
        ints: [1, 42, -128],
        doubles: [1.123, 4, 5.333, 1.22, 1.22, 1.22],
        strings: null,
      );
      obj2 = Model(
        bools: [true, true, false],
        ints: [4],
        doubles: [null],
        strings: ['Foo', 'bar'],
      );
      obj3 = Model(
        bools: [true],
        ints: [0, 123],
        doubles: [3.141592653, null, null],
        strings: ['a', 'b', 'c', 'd'],
      );
      obj4 = Model(
        bools: [true, true, false, true],
        ints: [-1, 1],
        doubles: [4, 12.2, 12.43],
        strings: ['', 'abc', null],
      );
      obj5 = Model(
        bools: [true, true, true, true, true, false],
        ints: [],
        doubles: [],
        strings: [null, null],
      );

      isar.writeTxn(
        (isar) => isar.models.putAll([obj1, obj2, obj3, obj4, obj5]),
      );
    });

    isarTest('.isEmpty()', () {
      expect(isar.models.where().boolsIsEmpty(), [obj1]);
      expect(isar.models.where().intsIsEmpty(), [obj5]);
      expect(isar.models.where().doublesIsEmpty(), [obj5]);
      expect(isar.models.where().stringsIsEmpty(), isEmpty);
    });

    isarTest('.isNotEmpty()', () {
      expect(
        isar.models.where().boolsIsNotEmpty(),
        [obj2, obj3, obj4, obj5],
      );
      expect(
        isar.models.where().intsIsNotEmpty(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        isar.models.where().doublesIsNotEmpty(),
        [obj1, obj2, obj3, obj4],
      );
      expect(
        isar.models.where().stringsIsNotEmpty(),
        [obj2, obj3, obj4, obj5],
      );
    });
  });
}
