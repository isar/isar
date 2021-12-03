import 'package:isar/isar.dart';
import 'package:isar_test/name_model.dart';
import 'package:isar_test/utils/open.dart';
import 'package:test/test.dart';
import 'package:isar_test/isar.g.dart';

void main() {
  group('Name', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar();
    });

    tearDown(() async {
      await isar.close();
    });

    test('json', () async {
      await isar.writeTxn((isar) => isar.nameModels.put(
            NameModel()
              ..value = 'test'
              ..otherValue = 'test2',
          ));

      expect(await isar.nameModels.where().exportJson(), [
        {
          'idN': Isar.minId,
          'valueN': 'test',
          'otherValueN': 'test2',
        },
      ]);
    });
  });
}
