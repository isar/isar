import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'max_size_test.g.dart';

@collection
class Model {
  final Id id = Isar.autoIncrement;

  final value = '123456789' * 1000;
}

void main() {
  group('Max Size', () {
    test('default', () async {
      final isar = await openTempIsar([ModelSchema]);
      await isar.writeTxn(() async {
        // TODO: figure out why 10000 doesn't work on armv7 Android
        await isar.models.putAll(List.filled(1000, Model()));
      });
    });

    test('10MB', () async {
      final isar = await openTempIsar([ModelSchema], maxSizeMiB: 10);

      expect(
        isar.writeTxn(() async {
          await isar.models.putAll(List.filled(1000, Model()));
        }),
        throwsIsarError('The database is full'),
      );

      await isar.writeTxn(() async {
        await isar.models.putAll(List.filled(50, Model()));
      });
    });
  });
}
