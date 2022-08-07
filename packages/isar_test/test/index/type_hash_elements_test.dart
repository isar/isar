import 'package:isar/isar.dart';
import 'package:test/test.dart';

import '../util/common.dart';
import '../util/sync_async_helper.dart';

part 'type_hash_elements_test.g.dart';

@Collection()
class HashElementsIndexesModel {
  HashElementsIndexesModel({
    required this.stringListSensitiveIndex,
    required this.stringListInsensitiveIndex,
  });
  Id? id;

  @Index(type: IndexType.hashElements, caseSensitive: true)
  List<String> stringListSensitiveIndex;

  @Index(type: IndexType.hashElements, caseSensitive: false)
  List<String> stringListInsensitiveIndex;

  @override
  // ignore: hash_and_equals
  bool operator ==(dynamic other) {
    return other is HashElementsIndexesModel &&
        listEquals(stringListSensitiveIndex, other.stringListSensitiveIndex) &&
        listEquals(
          stringListInsensitiveIndex,
          other.stringListInsensitiveIndex,
        );
  }

  @override
  String toString() {
    return 'HashElementsIndexModel{stringListSensitiveIndex: '
        '$stringListSensitiveIndex, stringListInsensitiveIndex: '
        '$stringListInsensitiveIndex}';
  }
}

void main() {
  group('Index hash elements type', () {
    late Isar isar;

    late HashElementsIndexesModel model0;
    late HashElementsIndexesModel model1;
    late HashElementsIndexesModel model2;
    late HashElementsIndexesModel model3;
    late HashElementsIndexesModel model4;

    setUp(() async {
      isar = await openTempIsar([HashElementsIndexesModelSchema]);

      model0 = HashElementsIndexesModel(
        stringListSensitiveIndex: ['Foo', 'bAR', '', ''],
        stringListInsensitiveIndex: ['fOo', 'BaR'],
      );
      model1 = HashElementsIndexesModel(
        stringListSensitiveIndex: [
          'Γαζέες καὶ μυρτιὲς δὲν θὰ βρῶ πιὰ στὸ χρυσαφὶ ξέφωτο',
          'The quick brown fox jumps over the lazy dog',
          'イロハニホヘト チリヌルヲ ワカヨタレソ ツネナラム',
          'Pchnąć w tę łódź jeża lub ośm skrzyń fig',
          'В чащах юга жил бы цитрус? Да, но фальшивый экземпляр!',
        ],
        stringListInsensitiveIndex: ['FoO', 'bAr'],
      );
      model2 = HashElementsIndexesModel(
        stringListSensitiveIndex: [],
        stringListInsensitiveIndex: [],
      );
      model3 = HashElementsIndexesModel(
        stringListSensitiveIndex: [
          'Pijamalı hasta, yağız şoföre çabucak güvendi.',
          '0',
          '\u0000',
          'Δ',
          '͌',
          '⋮',
        ],
        stringListInsensitiveIndex: ['BaR', 'fOo'],
      );
      model4 = HashElementsIndexesModel(
        stringListSensitiveIndex: ['\u0000', '0'],
        stringListInsensitiveIndex: ['0', '\u0000'],
      );

      await isar.tWriteTxn(() async {
        await isar.hashElementsIndexesModels.tPutAll([
          model0,
          model1,
          model2,
          model3,
          model4,
        ]);
      });
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    isarTest('Query List<String> sensitive index', () async {
      final result1 = await isar.hashElementsIndexesModels
          .where()
          .stringListSensitiveIndexElementEqualTo('Foo')
          .tFindAll();
      expect(result1, [model0]);

      final result2 = await isar.hashElementsIndexesModels
          .where()
          .stringListSensitiveIndexElementEqualTo('')
          .tFindAll();
      expect(result2, [model0]);
    });

    isarTest('Query List<String> insensitive index', () async {
      final result1 = await isar.hashElementsIndexesModels
          .where()
          .stringListInsensitiveIndexElementEqualTo('bar')
          .tFindAll();
      expect(result1, {model0, model1, model3});

      final result2 = await isar.hashElementsIndexesModels
          .where()
          .stringListInsensitiveIndexElementEqualTo('')
          .tFindAll();
      expect(result2, <HashElementsIndexesModel>[]);
    });
  });
}
