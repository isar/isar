import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'filter_list_length_test.g.dart';

@Collection()
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
      await qEqualSet(
        isar.models.filter().boolsLengthEqualTo(1).tFindAll(),
        [obj3],
      );

      await qEqualSet(
        isar.models.filter().intsLengthEqualTo(2).tFindAll(),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.models.filter().doublesLengthEqualTo(6).tFindAll(),
        [obj1],
      );

      await qEqualSet(
        isar.models.filter().doublesLengthEqualTo(42).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.models
            .filter()
            .doublesLengthEqualTo(9223372036854775807)
            .tFindAll(),
        [],
      );
    });

    isarTest('.lengthGreaterThan()', () async {
      await qEqualSet(
        isar.models.filter().boolsLengthGreaterThan(3).tFindAll(),
        [obj4, obj5],
      );

      await qEqualSet(
        isar.models.filter().boolsLengthGreaterThan(4).tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.models
            .filter()
            .boolsLengthGreaterThan(4, include: true)
            .tFindAll(),
        [obj4, obj5],
      );

      await qEqualSet(
        isar.models.filter().intsLengthGreaterThan(3).tFindAll(),
        [],
      );

      await qEqualSet(
        isar.models.filter().boolsLengthGreaterThan(0).tFindAll(),
        [obj2, obj3, obj4, obj5],
      );
    });

    isarTest('.lengthLessThan()', () async {
      await qEqualSet(
        isar.models.filter().boolsLengthLessThan(3).tFindAll(),
        [obj1, obj3],
      );

      await qEqualSet(
        isar.models.filter().boolsLengthLessThan(3, include: true).tFindAll(),
        [obj1, obj2, obj3],
      );

      await qEqualSet(
        isar.models.filter().intsLengthLessThan(2).tFindAll(),
        [obj2, obj5],
      );

      await qEqualSet(
        isar.models.filter().doublesLengthLessThan(0, include: true).tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.models.filter().stringsLengthLessThan(42).tFindAll(),
        [obj2, obj3, obj4, obj4, obj5],
      );

      await qEqualSet(
        isar.models.filter().stringsLengthLessThan(2).tFindAll(),
        [],
      );
    });

    isarTest('.lengthBetween()', () async {
      await qEqualSet(
        isar.models.filter().boolsLengthBetween(2, 6).tFindAll(),
        [obj2, obj4, obj5],
      );

      await qEqualSet(
        isar.models
            .filter()
            .boolsLengthBetween(2, 6, includeUpper: false)
            .tFindAll(),
        [obj2, obj4],
      );

      await qEqualSet(
        isar.models.filter().intsLengthBetween(0, 42).tFindAll(),
        [obj1, obj2, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.models
            .filter()
            .intsLengthBetween(0, 42, includeLower: false)
            .tFindAll(),
        [obj1, obj2, obj3, obj4],
      );

      await qEqualSet(
        isar.models.filter().doublesLengthBetween(2, 3).tFindAll(),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.models.filter().doublesLengthBetween(0, 0).tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.models
            .filter()
            .doublesLengthBetween(
              0,
              1,
              includeLower: false,
            )
            .tFindAll(),
        [obj2],
      );

      await qEqualSet(
        isar.models.filter().stringsLengthLessThan(3).tFindAll(),
        [obj2, obj5],
      );
    });

    isarTest('.isEmpty()', () async {
      await qEqualSet(
        isar.models.filter().boolsIsEmpty().tFindAll(),
        [obj1],
      );
      await qEqualSet(
        isar.models.filter().intsIsEmpty().tFindAll(),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().doublesIsEmpty().tFindAll(),
        [obj5],
      );
      await qEqualSet(
        isar.models.filter().stringsIsEmpty().tFindAll(),
        [],
      );
    });
  });
}
