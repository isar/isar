import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'multi_entry_test.g.dart';

@Collection()
class MultiEntryIndexModel {
  MultiEntryIndexModel({
    required this.bools,
    required this.ints,
    required this.doubles,
    required this.dateTimes,
    required this.stringsSensitive,
    required this.stringsInsensitive,
  });

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  final List<bool> bools;

  @Index(type: IndexType.value)
  final List<int> ints;

  @Index(type: IndexType.value)
  final List<double> doubles;

  @Index(type: IndexType.value)
  final List<DateTime> dateTimes;

  @Index(type: IndexType.value, caseSensitive: true)
  final List<String> stringsSensitive;

  @Index(type: IndexType.value, caseSensitive: false)
  final List<String> stringsInsensitive;

  @override
  String toString() {
    return 'MultiEntryIndexModel{id: $id}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiEntryIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(bools, other.bools) &&
          listEquals(ints, other.ints) &&
          listEquals(doubles, other.doubles) &&
          listEquals(dateTimes, other.dateTimes) &&
          listEquals(stringsSensitive, other.stringsSensitive) &&
          listEquals(stringsInsensitive, other.stringsInsensitive);
}

@Collection()
class MultiEntryNullableIndexModel {
  MultiEntryNullableIndexModel({
    required this.bools,
    required this.ints,
    required this.doubles,
    required this.dateTimes,
    required this.stringsSensitive,
    required this.stringsInsensitive,
  });

  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  final List<bool?>? bools;

  @Index(type: IndexType.value)
  final List<int?>? ints;

  @Index(type: IndexType.value)
  final List<double?>? doubles;

  @Index(type: IndexType.value)
  final List<DateTime?>? dateTimes;

  @Index(type: IndexType.value, caseSensitive: true)
  final List<String?>? stringsSensitive;

  @Index(type: IndexType.value, caseSensitive: false)
  final List<String?>? stringsInsensitive;

  @override
  String toString() {
    return 'MultiEntryIndexModel{id: $id}';
  }

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiEntryNullableIndexModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          listEquals(bools, other.bools) &&
          listEquals(ints, other.ints) &&
          listEquals(doubles, other.doubles) &&
          listEquals(dateTimes, other.dateTimes) &&
          listEquals(stringsSensitive, other.stringsSensitive) &&
          listEquals(stringsInsensitive, other.stringsInsensitive);
}

void main() {
  group('Multi entry index', () {
    late Isar isar;

    late MultiEntryIndexModel obj0;
    late MultiEntryIndexModel obj1;
    late MultiEntryIndexModel obj2;
    late MultiEntryIndexModel obj3;
    late MultiEntryIndexModel obj4;
    late MultiEntryIndexModel obj5;

    setUp(() async {
      isar = await openTempIsar([MultiEntryIndexModelSchema]);

      obj0 = MultiEntryIndexModel(
        bools: [true, true],
        ints: [0, 12, 0],
        doubles: [0.0, 42.4, 52, 1],
        dateTimes: [DateTime(2020)],
        stringsSensitive: ['Tomatoes', 'Foo'],
        stringsInsensitive: ['FOO', 'baR', 'FoO'],
      );
      obj1 = MultiEntryIndexModel(
        bools: [],
        ints: [28, 65535, 400],
        doubles: [3.141592658979],
        dateTimes: [DateTime(1920, 8, 9), DateTime(2000, 2, 2)],
        stringsSensitive: ['books', 'foo'],
        stringsInsensitive: ['BAR'],
      );
      obj2 = MultiEntryIndexModel(
        bools: [],
        ints: [],
        doubles: [],
        dateTimes: [],
        stringsSensitive: [],
        stringsInsensitive: [],
      );
      obj3 = MultiEntryIndexModel(
        bools: [false],
        ints: [123, -123, -0],
        doubles: [123.512312512, 1123.43],
        dateTimes: [DateTime(1921, 1, 29), DateTime(1456, 3, 11)],
        stringsSensitive: ['fork', 'John'],
        stringsInsensitive: ['PoTaToEs', ''],
      );
      obj4 = MultiEntryIndexModel(
        bools: [true, true, true, false],
        ints: [42, 0042, 0xffff],
        doubles: [0x0042, 43.4123],
        dateTimes: [DateTime(2022, 1, 3), DateTime(1921, 1, 29)],
        stringsSensitive: ['forks'],
        stringsInsensitive: ['potato', 'TOMATO'],
      );
      obj5 = MultiEntryIndexModel(
        bools: [false, false, false],
        ints: [-154123, 3],
        doubles: [234.34, -123e3],
        dateTimes: [DateTime(1204512, 1, 3), DateTime(1970)],
        stringsSensitive: ['FORK', 'Joe'],
        stringsInsensitive: ['foo', 'bar', 'tomato', 'fries'],
      );

      await isar.tWriteTxn(
        () => isar.multiEntryIndexModels.tPutAll([
          obj0,
          obj1,
          obj2,
          obj3,
          obj4,
          obj5,
        ]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Bools query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().boolsElementEqualTo(true).tFindAll(),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementNotEqualTo(false)
            .tFindAll(),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementEqualTo(false)
            .tFindAll(),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementNotEqualTo(true)
            .tFindAll(),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyBoolsElement().tFindAll(),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementEqualTo(true)
            .or()
            .boolsElementEqualTo(true)
            .or()
            .boolsElementEqualTo(true)
            .tFindAll(),
        [obj0, obj4],
      );
      return;
    });

    isarTest('Ints query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementEqualTo(42).tFindAll(),
        [obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementEqualTo(0xffff)
            .tFindAll(),
        [obj1, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementNotEqualTo(0xffff)
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementLessThan(0).tFindAll(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementLessThan(0, include: true)
            .tFindAll(),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementGreaterThan(42)
            .tFindAll(),
        [obj1, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementNotEqualTo(0).tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementBetween(0, 20).tFindAll(),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementEqualTo(0xffff)
            .or()
            .intsElementLessThan(-42)
            .tFindAll(),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementBetween(0, 8)
            .or()
            .intsElementBetween(0, 9)
            .tFindAll(),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyIntsElement().tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Doubles query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().doublesElementLessThan(0).tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .doublesElementGreaterThan(123.456)
            .tFindAll(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .doublesElementBetween(2, 64)
            .tFindAll(),
        [obj0, obj1, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyDoublesElement().tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .doublesElementGreaterThan(123.456)
            .or()
            .doublesElementGreaterThan(123.456)
            .tFindAll(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .doublesElementBetween(0.0000001, 0.0002)
            .tFindAll(),
        [],
      );
    });

    isarTest('DateTimes query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1970))
            .tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(2000, 2, 2))
            .tFindAll(),
        [obj1],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementNotEqualTo(DateTime(2020))
            .tFindAll(),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementLessThan(DateTime(2000))
            .tFindAll(),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementLessThan(DateTime(0))
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementGreaterThan(DateTime(2010, 4, 22))
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementBetween(DateTime(2005), DateTime(2030))
            .tFindAll(),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyDateTimesElement().tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1970))
            .or()
            .dateTimesElementBetween(DateTime(1969), DateTime(1971))
            .tFindAll(),
        [obj5],
      );
    });

    isarTest('Strings sensitive query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementEqualTo('fork')
            .tFindAll(),
        [obj3],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementNotEqualTo('forks')
            .tFindAll(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementLessThan('Greek')
            .tFindAll(),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementGreaterThan('bee')
            .tFindAll(),
        [obj1, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementBetween('Fork', 'Potato')
            .tFindAll(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('FO')
            .tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('fork')
            .tFindAll(),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('Qwerty')
            .tFindAll(),
        [],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .anyStringsSensitiveElement()
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementEqualTo('foo')
            .or()
            .stringsSensitiveElementEqualTo('foo')
            .tFindAll(),
        [obj1],
      );
    });

    isarTest('Strings insensitive query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('foo')
            .tFindAll(),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('')
            .tFindAll(),
        [obj3],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementNotEqualTo('bar')
            .tFindAll(),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementLessThan('D')
            .tFindAll(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementGreaterThan('KeTcHuP')
            .tFindAll(),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementBetween('abc', 'def')
            .tFindAll(),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .anyStringsInsensitiveElement()
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Multi index query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementEqualTo(true)
            .or()
            .dateTimesElementEqualTo(DateTime(2020))
            .or()
            .intsElementEqualTo(123)
            .tFindAll(),
        [obj0, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('po')
            .or()
            .stringsSensitiveElementStartsWith('for')
            .or()
            .boolsElementNotEqualTo(false)
            .tFindAll(),
        [obj0, obj3, obj4],
      );
    });
  });

  group('Multi entry nullable index', () {
    late Isar isar;

    late MultiEntryNullableIndexModel obj0;
    late MultiEntryNullableIndexModel obj1;
    late MultiEntryNullableIndexModel obj2;
    late MultiEntryNullableIndexModel obj3;
    late MultiEntryNullableIndexModel obj4;
    late MultiEntryNullableIndexModel obj5;

    setUp(() async {
      isar = await openTempIsar([MultiEntryNullableIndexModelSchema]);

      obj0 = MultiEntryNullableIndexModel(
        bools: [true, null],
        ints: null,
        doubles: [42.42, 20, -400],
        dateTimes: [DateTime(2020), DateTime(2030, 3, 23)],
        stringsSensitive: [null, ''],
        stringsInsensitive: ['FOO', 'baR'],
      );
      obj1 = MultiEntryNullableIndexModel(
        bools: [null],
        ints: [42, 64, 32],
        doubles: null,
        dateTimes: null,
        stringsSensitive: ['Tomatoes', 'Potatoes'],
        stringsInsensitive: ['foo', 'BAR', null],
      );
      obj2 = MultiEntryNullableIndexModel(
        bools: null,
        ints: null,
        doubles: null,
        dateTimes: null,
        stringsSensitive: null,
        stringsInsensitive: null,
      );
      obj3 = MultiEntryNullableIndexModel(
        bools: [null],
        ints: [null],
        doubles: [null],
        dateTimes: [null],
        stringsSensitive: [null],
        stringsInsensitive: [null],
      );
      obj4 = MultiEntryNullableIndexModel(
        bools: [true, true, false],
        ints: [null, null, 29],
        doubles: [3.14159265358979, null, 0],
        dateTimes: [
          DateTime(1970, 2, 8),
          DateTime(2000, 4, 3),
          DateTime(1560, 8, 27),
        ],
        stringsSensitive: ['potato', 'fries', 'rice'],
        stringsInsensitive: ['BAr', null, ''],
      );
      obj5 = MultiEntryNullableIndexModel(
        bools: [true, null, false, null, true],
        ints: [99, 0xffff, 42, 32],
        doubles: [null, 24.32, 41.43],
        dateTimes: [null, DateTime(1999, 3, 21)],
        stringsSensitive: ['', '', 'Potatoes'],
        stringsInsensitive: ['bar', 'BAR', null, 'foo'],
      );

      await isar.tWriteTxn(
        () => isar.multiEntryNullableIndexModels.tPutAll([
          obj0,
          obj1,
          obj2,
          obj3,
          obj4,
          obj5,
        ]),
      );
    });

    tearDown(() => isar.close());

    isarTest('Bools query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementEqualTo(true)
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementNotEqualTo(false)
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementIsNull()
            .tFindAll(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementIsNotNull()
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyBoolsElement().tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Ints query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementEqualTo(42)
            .tFindAll(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementNotEqualTo(42)
            .tFindAll(),
        [obj1, obj3, obj4, obj5],
      );

      // FIXME: lessThan on nullable fields also return null values.
      // We could fix this be adding a lower bound in the query and excluding it
      // await qEqualSet(
      //   isar.multiEntryNullableIndexModels
      //       .where()
      //       .intsElementLessThan(0)
      //       .tFindAll(),
      //   [],
      // );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementGreaterThan(90)
            .tFindAll(),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementBetween(0, 50)
            .tFindAll(),
        [obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementIsNotNull()
            .tFindAll(),
        [obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementIsNull()
            .tFindAll(),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyIntsElement().tFindAll(),
        [obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Doubles query', () async {
      // FIXME: Same as ints query
      // await qEqualSet(
      //   isar.multiEntryNullableIndexModels
      //       .where()
      //       .doublesElementLessThan(10)
      //       .tFindAll(),
      //   [obj0],
      // );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .doublesElementGreaterThan(40)
            .tFindAll(),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .doublesElementBetween(0, 32)
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .doublesElementIsNull()
            .tFindAll(),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .doublesElementIsNotNull()
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .anyDoublesElement()
            .tFindAll(),
        [obj0, obj3, obj4, obj5],
      );
    });

    isarTest('DateTimes query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1999, 3, 21))
            .or()
            .dateTimesElementEqualTo(DateTime(2020))
            .tFindAll(),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementNotEqualTo(DateTime(2020))
            .tFindAll(),
        [obj0, obj3, obj4, obj5],
      );

      // FIXME: Same as ints lessThan
      // Could fix with lower bound in generator
      // await qEqualSet(
      //   isar.multiEntryNullableIndexModels
      //       .where()
      //       .dateTimesElementLessThan(DateTime(2000))
      //       .tFindAll(),
      //   [obj4, obj5],
      // );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementGreaterThan(DateTime(2005, 1, 4))
            .tFindAll(),
        [obj0],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementBetween(DateTime(2000), DateTime(2020))
            .tFindAll(),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementIsNull()
            .tFindAll(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementIsNotNull()
            .tFindAll(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .anyDateTimesElement()
            .tFindAll(),
        [obj0, obj3, obj4, obj5],
      );
    });

    isarTest('Strings sensitive query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementEqualTo('Potatoes')
            .tFindAll(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementEqualTo('')
            .tFindAll(),
        [obj0, obj5],
      );

      // FIXME: Same issue as ints lessThan
      // await qEqualSet(
      //   isar.multiEntryNullableIndexModels
      //       .where()
      //       .stringsSensitiveElementLessThan('aaaa')
      //       .tFindAll(),
      //   [obj0, obj1, obj5],
      // );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementGreaterThan('aaaa')
            .tFindAll(),
        [obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementBetween('P', 'b')
            .tFindAll(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementIsNull()
            .tFindAll(),
        [obj0, obj3],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementIsNotNull()
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith('Po')
            .tFindAll(),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith('')
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .anyStringsSensitiveElement()
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Strings insensitive query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('bAR')
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('')
            .tFindAll(),
        [obj4],
      );

      // FIXME: Same issue as ints lessThan
      // await qEqualSet(
      //   isar.multiEntryNullableIndexModels
      //       .where()
      //       .stringsInsensitiveElementLessThan('desert')
      //       .tFindAll(),
      //   [obj0, obj1, obj4, obj5],
      // );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementGreaterThan('bar')
            .tFindAll(),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementBetween('a', 'C')
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementIsNull()
            .tFindAll(),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementIsNotNull()
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('ba')
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('f')
            .tFindAll(),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .anyStringsInsensitiveElement()
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Multi index query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementIsNull()
            .or()
            .dateTimesElementIsNull()
            .tFindAll(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementIsNotNull()
            .or()
            .dateTimesElementEqualTo(DateTime(2020))
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith('fo')
            .or()
            .stringsInsensitiveElementStartsWith('b')
            .tFindAll(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementGreaterThan(DateTime(2020))
            .or()
            .stringsInsensitiveElementIsNull()
            .or()
            .stringsInsensitiveElementIsNull()
            .or()
            .stringsInsensitiveElementIsNull()
            .tFindAll(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });
  });
}
