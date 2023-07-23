import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'auto_increment_test.g.dart';

@collection
class Model {
  Model(this.id);

  final int id;
}

void main() {
  group('Auto increment', () {
    late Isar isar;

    setUp(() {
      isar = openTempIsar([ModelSchema]);
    });

    isarTest('increases', () {
      expect(isar.models.autoIncrement(), 1);
      expect(isar.models.autoIncrement(), 2);
      expect(isar.models.autoIncrement(), 3);
    });

    isarTest('adjusts after insert', () {
      expect(isar.models.autoIncrement(), 1);
      expect(isar.models.autoIncrement(), 2);
      expect(isar.models.autoIncrement(), 3);

      isar.write((isar) {
        isar.models.put(Model(100));
        isar.models.put(Model(200));
        isar.models.put(Model(300));
      });

      expect(isar.models.autoIncrement(), 301);
      expect(isar.models.autoIncrement(), 302);
      expect(isar.models.autoIncrement(), 303);
    });

    isarTest('persists', () {
      final isarName = isar.name;

      expect(isar.models.autoIncrement(), 1);
      isar.write((isar) {
        isar.models.put(Model(isar.models.autoIncrement()));
      });
      expect(isar.close(), true);

      isar = openTempIsar([ModelSchema], name: isarName);
      expect(isar.models.autoIncrement(), 3);
    });
  });
}
