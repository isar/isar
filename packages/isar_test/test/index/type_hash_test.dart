import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'type_hash_test.g.dart';

@Collection()
class HashIndexesModel {
  HashIndexesModel({
    required this.stringSensitiveIndex,
    required this.stringInsensitiveIndex,
    required this.boolListIndex,
    required this.intListIndex,
    required this.dateTimeListIndex,
    required this.stringListSensitiveIndex,
    required this.stringListInsensitiveIndex,
  });
  Id? id;

  @Index(type: IndexType.hash, caseSensitive: true)
  String stringSensitiveIndex;

  @Index(type: IndexType.hash, caseSensitive: false)
  String stringInsensitiveIndex;

  @Index(type: IndexType.hash)
  List<bool> boolListIndex;

  @Index(type: IndexType.hash)
  List<int> intListIndex;

  @Index(type: IndexType.hash)
  List<DateTime> dateTimeListIndex;

  @Index(type: IndexType.hash, caseSensitive: true)
  List<String> stringListSensitiveIndex;

  @Index(type: IndexType.hash, caseSensitive: false)
  List<String> stringListInsensitiveIndex;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HashIndexesModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stringSensitiveIndex == other.stringSensitiveIndex &&
          stringInsensitiveIndex == other.stringInsensitiveIndex &&
          listEquals(boolListIndex, other.boolListIndex) &&
          listEquals(intListIndex, other.intListIndex) &&
          listEquals(dateTimeListIndex, other.dateTimeListIndex) &&
          listEquals(
            stringListSensitiveIndex,
            other.stringListSensitiveIndex,
          ) &&
          listEquals(
            stringListInsensitiveIndex,
            other.stringListInsensitiveIndex,
          );

  @override
  String toString() {
    return 'HashIndexesModel($id)';
  }
}

void main() {
  group('Index hash type', () {
    late Isar isar;
    late HashIndexesModel model0;
    late HashIndexesModel model1;

    setUp(() async {
      isar = await openTempIsar([HashIndexesModelSchema]);

      await isar.tWriteTxn(() async {
        model0 = HashIndexesModel(
          stringSensitiveIndex: 'My index',
          stringInsensitiveIndex: 'John Smith',
          boolListIndex: [true, true, false],
          intListIndex: [1, 99, 42],
          dateTimeListIndex: [DateTime(2001, 4, 4), DateTime(1995, 7, 27)],
          stringListSensitiveIndex: ['FOO'],
          stringListInsensitiveIndex: ['loREM', 'IPSum'],
        );
        model1 = HashIndexesModel(
          stringSensitiveIndex: 'mY INDEX',
          stringInsensitiveIndex: 'jOHN SMiTh',
          boolListIndex: List.filled(100, true),
          intListIndex: [6, -5],
          dateTimeListIndex: [DateTime(1992, 1, 24)],
          stringListSensitiveIndex: ['foo', 'bar'],
          stringListInsensitiveIndex: ['LORem', 'ipsum'],
        );
        await isar.hashIndexesModels.tPutAll([model0, model1]);
      });
    });

    tearDown(() => isar.close());

    isarTest('Query String sensitive index', () async {
      final result = await isar.hashIndexesModels
          .where()
          .stringSensitiveIndexNotEqualTo('mY INDEX')
          .tFindAll();
      expect(result, [model0]);
    });

    isarTest('Query String insensitive index', () async {
      final result1 = await isar.hashIndexesModels
          .where()
          .stringInsensitiveIndexEqualTo('john smith')
          .tFindAll();
      expect(result1, {model0, model1});

      final result2 = await isar.hashIndexesModels
          .where()
          .stringInsensitiveIndexEqualTo('john doe')
          .tFindAll();
      expect(result2, <HashIndexesModel>[]);
    });

    isarTest('Query List<bool> index', () async {
      final result = await isar.hashIndexesModels
          .where()
          .boolListIndexEqualTo([true, true, false]).findAll();
      expect(result, [model0]);
    });

    isarTest('query List<int> index', () async {
      final result = await isar.hashIndexesModels
          .where()
          .intListIndexNotEqualTo([6, -5]).tFindAll();
      expect(result, [model0]);
    });

    // FIXME: type issue with List<DateTime> hash
    // type 'MappedListIterable<DateTime, int?>' is not a subtype of type 'List<int?>' in type cast
    // isarTest("Query List<DateTime> index", () async {
    //   final result = await isar.hashIndexesModels
    //       .where()
    //       .dateTimeListIndexEqualTo([DateTime(1992, 1, 24)]).tFindAll();
    //   expect(result, [model1]);
    // });

    isarTest('Query List<String> sensitive index', () async {
      final result = await isar.hashIndexesModels
          .where()
          .stringListSensitiveIndexEqualTo([]).tFindAll();
      expect(result, <HashIndexesModel>[]);
    });

    isarTest('Query List<String> insensitive index', () async {
      final result1 = await isar.hashIndexesModels
          .where()
          .stringListInsensitiveIndexEqualTo(['lorem', 'IPSUM']).tFindAll();
      expect(result1, {model0, model1});

      final result2 = await isar.hashIndexesModels
          .where()
          .stringListInsensitiveIndexEqualTo(['lorem']).tFindAll();
      expect(result2, <HashIndexesModel>[]);
    });

    isarTest('Query every index', () async {
      final result = await isar.hashIndexesModels
          .where()
          .stringSensitiveIndexNotEqualTo('My index')
          .or()
          .stringInsensitiveIndexEqualTo('JOHN SMIth')
          .or()
          .boolListIndexEqualTo([true, true, false])
          .or()
          .intListIndexNotEqualTo([])
          .or()
          // FIXME: type issue with List<DateTime> hash
          // .dateTimeListIndexNotEqualTo([DateTime(1234, 1, 1)])
          // .or()
          .stringListSensitiveIndexEqualTo(['foo', 'bar'])
          .or()
          .stringListInsensitiveIndexEqualTo(['lorem', 'ipsum'])
          .tFindAll();
      expect(result, {model0, model1});
    });
  });
}
