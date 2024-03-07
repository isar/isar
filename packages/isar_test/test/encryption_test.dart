import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'encryption_test.g.dart';

@collection
class Model {
  Model(this.name);

  @id
  final String name;

  @override
  bool operator ==(Object other) => other is Model && name == other.name;
}

void main() {
  group('Encryption', () {
    isarTest('Correct key', isar: false, web: false, () async {
      final isarName = getRandomName();
      final isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
      );
      isar.write((isar) {
        isar.models.putAll([Model('test1'), Model('test2')]);
      });
      expect(isar.close(), true);

      final isar2 = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
        closeAutomatically: false,
      );
      expect(isar2.models.where().findAll(), [Model('test1'), Model('test2')]);
    });

    isarTest('Wrong key', isar: false, web: false, () async {
      final isarName = getRandomName();
      final isar = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
      );
      isar.write((isar) {
        isar.models.put(Model('test'));
      });
      expect(isar.close(), true);

      await expectLater(
        () => openTempIsar(
          [ModelSchema],
          name: isarName,
          encryptionKey: 'test2',
        ),
        throwsA(isA<EncryptionError>()),
      );
    });

    isarTest('Change key', isar: false, web: false, () async {
      final isarName = getRandomName();
      final isar1 = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'key1',
      );
      isar1.write((isar) => isar.models.put(Model('test1')));
      expect(isar1.close(), true);

      final isar2 = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'key1',
      );
      expect(isar2.models.where().findAll(), [Model('test1')]);

      isar2.changeEncryptionKey('key2');
      expect(isar2.models.where().findAll(), [Model('test1')]);
      isar2.write((isar) => isar.models.put(Model('test2')));
      expect(isar2.models.where().findAll(), [Model('test1'), Model('test2')]);
      expect(isar2.close(), true);

      // Using the old key (should throw)
      await expectLater(
        () => openTempIsar(
          [ModelSchema],
          name: isarName,
          encryptionKey: 'key1',
        ),
        throwsA(isA<EncryptionError>()),
      );

      final isar3 = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'key2',
      );
      expect(isar3.models.where().findAll(), [Model('test1'), Model('test2')]);

      isar3.write((isar) => isar.models.put(Model('test3')));
      isar3.changeEncryptionKey('key3');
      isar3.write((isar) => isar.models.put(Model('test4')));
      isar3.changeEncryptionKey('key4');
      isar3.write((isar) => isar.models.clear());
      isar3.write((isar) => isar.models.put(Model('test5')));
      isar3.changeEncryptionKey('key1');
      isar3.write((isar) => isar.models.put(Model('test6')));

      expect(isar3.models.where().findAll(), [Model('test5'), Model('test6')]);
      expect(isar3.close(), true);

      for (final oldKey in ['key2', 'key3', 'key4']) {
        // Using the old key (should throw)
        await expectLater(
          () => openTempIsar(
            [ModelSchema],
            name: isarName,
            encryptionKey: oldKey,
          ),
          throwsA(isA<EncryptionError>()),
        );
      }

      final isar4 = await openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'key1',
      );
      expect(isar4.models.where().findAll(), [Model('test5'), Model('test6')]);
      expect(isar4.close(), true);
    });
  });
}
