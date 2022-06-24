import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'index_type_value_test.g.dart';

@Collection()
class ValueIndexesModel {
  ValueIndexesModel({
    required this.boolIndex,
    required this.intIndex,
    required this.doubleIndex,
    required this.dateTimeIndex,
    required this.stringIndexSensitive,
    required this.stringIndexInsensitive,
    required this.boolListIndex,
    required this.intListIndex,
    required this.doubleListIndex,
    required this.dateTimeListIndex,
    required this.stringListSensitiveIndex,
    required this.stringListInsensitiveIndex,
  });
  int? id;

  @Index(type: IndexType.value)
  bool boolIndex;

  @Index(type: IndexType.value)
  int intIndex;

  @Index(type: IndexType.value)
  double doubleIndex;

  @Index(type: IndexType.value)
  DateTime dateTimeIndex;

  @Index(type: IndexType.value, caseSensitive: true)
  String stringIndexSensitive;

  @Index(type: IndexType.value, caseSensitive: false)
  String stringIndexInsensitive;

  @Index(type: IndexType.value)
  List<bool> boolListIndex;

  @Index(type: IndexType.value)
  List<int> intListIndex;

  @Index(type: IndexType.value)
  List<double> doubleListIndex;

  @Index(type: IndexType.value)
  List<DateTime> dateTimeListIndex;

  @Index(type: IndexType.value, caseSensitive: true)
  List<String> stringListSensitiveIndex;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String> stringListInsensitiveIndex;

  @override
  bool operator ==(Object other) {
    return other is ValueIndexesModel &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        boolIndex == other.boolIndex &&
        intIndex == other.intIndex &&
        doubleIndex == other.doubleIndex &&
        dateTimeIndex == other.dateTimeIndex &&
        stringIndexSensitive == other.stringIndexSensitive &&
        stringIndexInsensitive == other.stringIndexInsensitive &&
        listEquals(boolListIndex, boolListIndex) &&
        listEquals(intListIndex, other.intListIndex) &&
        listEquals(doubleListIndex, other.doubleListIndex) &&
        listEquals(dateTimeListIndex, other.dateTimeListIndex) &&
        listEquals(stringListSensitiveIndex, other.stringListSensitiveIndex) &&
        listEquals(
            stringListInsensitiveIndex, other.stringListInsensitiveIndex);
  }

  @override
  String toString() {
    return 'ValueIndexesModel{boolIndex: $boolIndex, intIndex: $intIndex, doubleIndex: $doubleIndex, dateTimeIndex: $dateTimeIndex, stringIndexSensitive: $stringIndexSensitive, stringIndexInsensitive: $stringIndexInsensitive, boolListIndex: $boolListIndex, intListIndex: $intListIndex, doubleListIndex: $doubleListIndex, dateTimeListIndex: $dateTimeListIndex, stringListSensitiveIndex: $stringListSensitiveIndex, stringListInsensitiveIndex: $stringListInsensitiveIndex}';
  }
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  group('Index value type', () {
    late Isar isar;
    late ValueIndexesModel model0;
    late ValueIndexesModel model1;

    setUp(() async {
      isar = await openTempIsar([ValueIndexesModelSchema]);

      await isar.tWriteTxn(() async {
        model0 = ValueIndexesModel(
          boolIndex: true,
          intIndex: 55,
          doubleIndex: 0.42,
          dateTimeIndex: DateTime(1950, 1, 13),
          stringIndexSensitive: 'My index',
          stringIndexInsensitive: 'fOo BaR',
          boolListIndex: [true, true, false],
          intListIndex: [1, 99, 42],
          doubleListIndex: [4.32, 8, 44.23, 1509182.1231089124089571209377],
          dateTimeListIndex: [DateTime(2001, 4, 4), DateTime(1995, 7, 27)],
          stringListSensitiveIndex: [],
          stringListInsensitiveIndex: ['Earth'],
        );
        model1 = ValueIndexesModel(
          boolIndex: false,
          intIndex: -123,
          doubleIndex: 4432.1,
          dateTimeIndex: DateTime(2100, 4, 4),
          stringIndexSensitive: 'mY INDEX',
          stringIndexInsensitive: 'FoO bAr',
          boolListIndex: List.filled(100, true),
          intListIndex: [6, -5],
          doubleListIndex: [-4.32, 8, 44, -152.001, -0.0],
          dateTimeListIndex: [DateTime(1992, 1, 24)],
          stringListSensitiveIndex: ['foo', 'bar'],
          stringListInsensitiveIndex: ['eArTh'],
        );
        await isar.valueIndexesModels.tPutAll([model0, model1]);
      });
    });

    tearDown(() => isar.close());

    isarTest('Query bool index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .boolIndexEqualTo(true)
          .tFindAll();
      expect(result, [model0]);
    });

    isarTest('Query int test', () async {
      final result1 = await isar.valueIndexesModels
          .where()
          .intIndexEqualTo(-123)
          .tFindAll();
      expect(result1, [model1]);

      final result2 =
          await isar.valueIndexesModels.where().intIndexEqualTo(-0).tFindAll();
      expect(result2, <ValueIndexesModel>[]);
    });

    isarTest('Query double index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .doubleIndexGreaterThan(4432.0999999999999)
          .tFindAll();
      expect(result, [model1]);
    });

    isarTest('query DateTime index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .dateTimeIndexEqualTo(DateTime(2100, 4, 4))
          .tFindAll();
      expect(result, [model1]);
    });

    isarTest('Query String sensitive index', () async {
      final result1 = await isar.valueIndexesModels
          .where()
          .stringIndexSensitiveNotEqualTo('mY INDEX')
          .tFindAll();
      expect(result1, [model0]);

      final result2 = await isar.valueIndexesModels
          .where()
          .stringIndexSensitiveStartsWith('mY')
          .tFindAll();
      expect(result2, [model1]);
    });

    isarTest('Query String insensitive index', () async {
      final result1 = await isar.valueIndexesModels
          .where()
          .stringIndexInsensitiveEqualTo('foo bar')
          .tFindAll();
      expect(result1, {model0, model1});

      final result2 = await isar.valueIndexesModels
          .where()
          .stringIndexInsensitiveStartsWith('f')
          .tFindAll();
      expect(result2, {model0, model1});

      final result3 = await isar.valueIndexesModels
          .where()
          .stringIndexInsensitiveGreaterThan('foo bar')
          .tFindAll();
      expect(result3, <ValueIndexesModel>[]);
    });

    isarTest('Query List<bool> index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .boolListIndexAnyEqualTo(false)
          .findAll();
      expect(result, [model0]);
    });

    isarTest('query List<int> index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .intListIndexAnyGreaterThan(42)
          .tFindAll();
      expect(result, [model0]);
    });

    isarTest('Query List<double> index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .doubleListIndexAnyLessThan(100)
          .tFindAll();
      expect(result, {model0, model1});
    });

    isarTest('Query List<DateTime> index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .dateTimeListIndexAnyLessThan(DateTime(1995))
          .tFindAll();
      expect(result, [model1]);
    });

    isarTest('Query List<String> sensitive index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .stringListSensitiveIndexAnyGreaterThan('d')
          .tFindAll();
      expect(result, [model1]);
    });

    isarTest('Query List<String> insensitive index', () async {
      final result1 = await isar.valueIndexesModels
          .where()
          .stringListInsensitiveIndexAnyEqualTo('earth')
          .tFindAll();
      expect(result1, {model0, model1});

      final result2 = await isar.valueIndexesModels
          .where()
          .stringListInsensitiveIndexAnyStartsWith('e')
          .tFindAll();
      expect(result2, {model0, model1});

      final result3 = await isar.valueIndexesModels
          .where()
          .stringListInsensitiveIndexAnyStartsWith('mars')
          .tFindAll();
      expect(result3, <ValueIndexesModel>[]);
    });

    isarTest('Query every index', () async {
      final result = await isar.valueIndexesModels
          .where()
          .boolIndexEqualTo(false)
          .or()
          .intIndexLessThan(-120)
          .or()
          .doubleIndexBetween(1000, 5000)
          .or()
          .dateTimeIndexEqualTo(DateTime(2100, 4, 4))
          .or()
          .stringIndexSensitiveNotEqualTo('My index')
          .or()
          .stringIndexInsensitiveStartsWith('foo')
          .or()
          .boolListIndexAnyNotEqualTo(false)
          .or()
          .intListIndexAnyLessThan(0)
          .or()
          .doubleListIndexAnyLessThan(-100)
          .or()
          .dateTimeListIndexAnyLessThan(DateTime(1995))
          .or()
          .stringListSensitiveIndexAnyEqualTo('foo')
          .or()
          .stringListInsensitiveIndexAnyStartsWith('e')
          .tFindAll();
      expect(result, {model0, model1});
    });
  });
}
