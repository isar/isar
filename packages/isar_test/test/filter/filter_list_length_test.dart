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

  Id id = Isar.autoIncrement;

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

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);

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

      await isar.tWriteTxn(
        () => isar.models.tPutAll([obj1, obj2, obj3, obj4, obj5]),
      );
    });

    isarTest('.lengthEqualTo()', () async {
      await qEqual(isar.models.filter().boolsLengthEqualTo(1), [obj3]);
      await qEqual(isar.models.filter().intsLengthEqualTo(2), [obj3, obj4]);
      await qEqual(isar.models.filter().doublesLengthEqualTo(6), [obj1]);
      await qEqual(isar.models.filter().doublesLengthEqualTo(42), []);
      await qEqual(
        isar.models.filter().doublesLengthEqualTo(9223372036854775807),
        [],
      );
    });

    isarTest('.lengthGreaterThan()', () async {
      await qEqual(
        isar.models.filter().boolsLengthGreaterThan(3),
        [obj4, obj5],
      );
      await qEqual(
        isar.models.filter().boolsLengthGreaterThan(4),
        [obj5],
      );
      await qEqual(
        isar.models.filter().boolsLengthGreaterThan(4, include: true),
        [obj4, obj5],
      );
      await qEqual(isar.models.filter().intsLengthGreaterThan(3), []);
      await qEqual(
        isar.models.filter().boolsLengthGreaterThan(0),
        [obj2, obj3, obj4, obj5],
      );
    });

    isarTest('.lengthLessThan()', () async {
      await qEqual(isar.models.filter().boolsLengthLessThan(3), [obj1, obj3]);
      await qEqual(
        isar.models.filter().boolsLengthLessThan(3, include: true),
        [obj1, obj2, obj3],
      );
      await qEqual(isar.models.filter().intsLengthLessThan(2), [obj2, obj5]);
      await qEqual(
        isar.models.filter().doublesLengthLessThan(0, include: true),
        [obj5],
      );
      await qEqual(
        isar.models.filter().stringsLengthLessThan(42),
        [obj2, obj3, obj4, obj5],
      );
      await qEqual(isar.models.filter().stringsLengthLessThan(2), []);
    });

    isarTest('.lengthBetween()', () async {
      await qEqual(
        isar.models.filter().boolsLengthBetween(2, 6),
        [obj2, obj4, obj5],
      );
      await qEqual(
        isar.models.filter().boolsLengthBetween(2, 6, includeUpper: false),
        [obj2, obj4],
      );
      await qEqual(
        isar.models.filter().intsLengthBetween(0, 42),
        [obj1, obj2, obj3, obj4, obj5],
      );
      await qEqual(
        isar.models.filter().intsLengthBetween(0, 42, includeLower: false),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        isar.models.filter().doublesLengthBetween(2, 3),
        [obj3, obj4],
      );
      await qEqual(isar.models.filter().doublesLengthBetween(0, 0), [obj5]);
      await qEqual(
        isar.models.filter().doublesLengthBetween(
              0,
              1,
              includeLower: false,
            ),
        [obj2],
      );
      await qEqual(isar.models.filter().stringsLengthLessThan(3), [obj2, obj5]);
    });

    isarTest('.isEmpty()', () async {
      await qEqual(isar.models.filter().boolsIsEmpty(), [obj1]);
      await qEqual(isar.models.filter().intsIsEmpty(), [obj5]);
      await qEqual(isar.models.filter().doublesIsEmpty(), [obj5]);
      await qEqual(isar.models.filter().stringsIsEmpty(), []);
    });

    isarTest('.isNotEmpty()', () async {
      await qEqual(
        isar.models.filter().boolsIsNotEmpty(),
        [obj2, obj3, obj4, obj5],
      );
      await qEqual(
        isar.models.filter().intsIsNotEmpty(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        isar.models.filter().doublesIsNotEmpty(),
        [obj1, obj2, obj3, obj4],
      );
      await qEqual(
        isar.models.filter().stringsIsNotEmpty(),
        [obj2, obj3, obj4, obj5],
      );
    });
  });
}
