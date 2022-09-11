import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'multi_entry_test.g.dart';

@collection
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

@collection
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

    isarTest('Bools query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().boolsElementEqualTo(true),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().boolsElementNotEqualTo(false),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().boolsElementEqualTo(false),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().boolsElementNotEqualTo(true),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyBoolsElement(),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .boolsElementEqualTo(true)
            .or()
            .boolsElementEqualTo(true)
            .or()
            .boolsElementEqualTo(true),
        [obj0, obj4],
      );
    });

    isarTest('Ints query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementEqualTo(42),
        [obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementEqualTo(0xffff),
        [obj1, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementNotEqualTo(0xffff),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementLessThan(0),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementLessThan(0, include: true),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementGreaterThan(42),
        [obj1, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementNotEqualTo(0),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().intsElementBetween(0, 20),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementEqualTo(0xffff)
            .or()
            .intsElementLessThan(-42),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .intsElementBetween(0, 8)
            .or()
            .intsElementBetween(0, 9),
        [obj0, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyIntsElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Doubles query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels.where().doublesElementLessThan(0),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().doublesElementGreaterThan(123.456),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().doublesElementBetween(2, 64),
        [obj0, obj1, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyDoublesElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .doublesElementGreaterThan(123.456)
            .or()
            .doublesElementGreaterThan(123.456),
        [obj3, obj5],
      );
    });

    isarTest('DateTimes query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1970)),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(2000, 2, 2)),
        [obj1],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementNotEqualTo(DateTime(2020)),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementLessThan(DateTime(2000)),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementLessThan(DateTime(0)),
        [],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementGreaterThan(DateTime(2010, 4, 22)),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementBetween(DateTime(2005), DateTime(2030)),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyDateTimesElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1970))
            .or()
            .dateTimesElementBetween(DateTime(1969), DateTime(1971)),
        [obj5],
      );
    });

    isarTest('Strings sensitive query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementEqualTo('fork'),
        [obj3],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementNotEqualTo('forks'),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementLessThan('Greek'),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementGreaterThan('bee'),
        [obj1, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementBetween('Fork', 'Potato'),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('FO'),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('fork'),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementStartsWith('Qwerty'),
        [],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyStringsSensitiveElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsSensitiveElementEqualTo('foo')
            .or()
            .stringsSensitiveElementEqualTo('foo'),
        [obj1],
      );
    });

    isarTest('Strings insensitive query', () async {
      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('foo'),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().stringsInsensitiveElementEqualTo(''),
        [obj3],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementNotEqualTo('bar'),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementLessThan('D'),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementGreaterThan('KeTcHuP'),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementBetween('abc', 'def'),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryIndexModels.where().anyStringsInsensitiveElement(),
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
            .intsElementEqualTo(123),
        [obj0, obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('po')
            .or()
            .stringsSensitiveElementStartsWith('for')
            .or()
            .boolsElementNotEqualTo(false),
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

    isarTest('Bools query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().boolsElementEqualTo(true),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementNotEqualTo(false),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().boolsElementIsNull(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().boolsElementIsNotNull(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyBoolsElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Ints query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementEqualTo(42),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementNotEqualTo(42),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementLessThan(0),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementGreaterThan(90),
        [obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementBetween(0, 50),
        [obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementIsNotNull(),
        [obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().intsElementIsNull(),
        [obj3, obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyIntsElement(),
        [obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Doubles query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().doublesElementLessThan(10),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .doublesElementGreaterThan(40),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().doublesElementBetween(0, 32),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().doublesElementIsNull(),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().doublesElementIsNotNull(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyDoublesElement(),
        [obj0, obj3, obj4, obj5],
      );
    });

    isarTest('DateTimes query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementEqualTo(DateTime(1999, 3, 21))
            .or()
            .dateTimesElementEqualTo(DateTime(2020)),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementNotEqualTo(DateTime(2020)),
        [obj0, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementLessThan(DateTime(2000)),
        [obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementGreaterThan(DateTime(2005, 1, 4)),
        [obj0],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .dateTimesElementBetween(DateTime(2000), DateTime(2020)),
        [obj0, obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().dateTimesElementIsNull(),
        [obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().dateTimesElementIsNotNull(),
        [obj0, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyDateTimesElement(),
        [obj0, obj3, obj4, obj5],
      );
    });

    isarTest('Strings sensitive query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementEqualTo('Potatoes'),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementEqualTo(''),
        [obj0, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementLessThan('aaaa'),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementGreaterThan('aaaa'),
        [obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementBetween('P', 'b'),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementIsNull(),
        [obj0, obj3],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementIsNotNull(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith('Po'),
        [obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith(''),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels.where().anyStringsSensitiveElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Strings insensitive query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementEqualTo('bAR'),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementEqualTo(''),
        [obj4],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementLessThan('desert'),
        [obj0, obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementGreaterThan('bar'),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementBetween('a', 'C'),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementIsNull(),
        [obj1, obj3, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementIsNotNull(),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('ba'),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsInsensitiveElementStartsWith('f'),
        [obj0, obj1, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .anyStringsInsensitiveElement(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });

    isarTest('Multi index query', () async {
      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .boolsElementIsNull()
            .or()
            .dateTimesElementIsNull(),
        [obj0, obj1, obj3, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .intsElementIsNotNull()
            .or()
            .dateTimesElementEqualTo(DateTime(2020)),
        [obj0, obj1, obj4, obj5],
      );

      await qEqualSet(
        isar.multiEntryNullableIndexModels
            .where()
            .stringsSensitiveElementStartsWith('fo')
            .or()
            .stringsInsensitiveElementStartsWith('b'),
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
            .stringsInsensitiveElementIsNull(),
        [obj0, obj1, obj3, obj4, obj5],
      );
    });
  });
}
