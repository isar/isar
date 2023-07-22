// ignore_for_file: hash_and_equals

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
    isarTest('Correct key', isar: false, () {
      final isarName = getRandomName();
      final isar = openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
      );
      isar.write((isar) {
        isar.models.putAll([Model('test1'), Model('test2')]);
      });
      expect(isar.close(), true);

      final isar2 = openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
        closeAutomatically: false,
      );
      expect(isar2.models.where().findAll(), [Model('test1'), Model('test2')]);
    });

    isarTest('Wrong key', isar: false, () {
      final isarName = getRandomName();
      final isar = openTempIsar(
        [ModelSchema],
        name: isarName,
        encryptionKey: 'test',
      );
      isar.write((isar) {
        isar.models.put(Model('test'));
      });
      expect(isar.close(), true);

      expect(
        () =>
            openTempIsar([ModelSchema], name: isarName, encryptionKey: 'test2'),
        throwsA(isA<EncryptionError>()),
      );
    });
  });
}
