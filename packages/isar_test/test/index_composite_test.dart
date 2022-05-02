import 'package:isar/isar.dart';
import 'package:test/test.dart';

import 'util/common.dart';
import 'util/sync_async_helper.dart';

part 'index_composite_test.g.dart';

@Collection()
class CompositeModel {
  int? id;

  @Index(
    composite: [CompositeIndex('stringValue')],
  )
  int? intValue;

  @Index(
    composite: [
      CompositeIndex(
        'stringValue2',
        type: IndexType.value,
      )
    ],
    unique: true,
  )
  String? stringValue;

  String? stringValue2;

  @override
  String toString() {
    return '{id: $id, intValue: $intValue, stringValue: $stringValue, stringValue2: $stringValue2}';
  }

  @override
  bool operator ==(other) {
    return (other is CompositeModel) &&
        other.id == id &&
        other.intValue == intValue &&
        other.stringValue == stringValue &&
        other.stringValue2 == stringValue2;
  }
}

void main() {
  testSyncAsync(tests);
}

void tests() {
  group('Composite', () {
    late Isar isar;
    late IsarCollection<CompositeModel> col;

    late CompositeModel obj1;
    late CompositeModel obj2;
    late CompositeModel obj3;
    late CompositeModel obj4;

    setUp(() async {
      isar = await openTempIsar([CompositeModelSchema]);
      col = isar.compositeModels;

      obj1 = CompositeModel()
        ..intValue = 1
        ..stringValue = '1'
        ..stringValue2 = 'a';
      obj2 = CompositeModel()
        ..intValue = 1
        ..stringValue = '1'
        ..stringValue2 = 'b';
      obj3 = CompositeModel()
        ..intValue = 2
        ..stringValue = '2'
        ..stringValue2 = 'a';
      obj4 = CompositeModel()
        ..intValue = 2
        ..stringValue = '2'
        ..stringValue2 = null;

      await isar.writeTxn((isar) async {
        await col.putAll([obj2, obj1, obj4, obj3]);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    isarTest('.put() duplicate index', () async {
      final newObj = CompositeModel()
        ..id = 5
        ..intValue = 1
        ..stringValue = 'a';
      await isar.tWriteTxn((isar) async {
        await isar.compositeModels.tPut(newObj);
      });

      qEqualSet(isar.compositeModels.where().tFindAll(),
          [obj1, obj2, obj3, obj4, newObj]);
    });

    /*isarTest('.put() duplicate unique index', () async {
      final newObj = CompositeModel()
        ..id = 5
        ..stringValue = '1'
        ..stringValue2 = 'b';

      await expectLater(
        () => isar.tWriteTxn((isar) async {
          await isar.compositeModels.tPut(newObj);
        }),
        throwsIsarError('unique'),
      );

      /*await isar.writeTxn((isar) async {
        await isar.compositeModels.put(newObj, replaceOnConflict: true);
      });

      qEqualSet(
        isar.compositeModels.where().findAll(),
        [obj1, obj3, obj4, newObj],
      );*/
    });*/
  });
}
