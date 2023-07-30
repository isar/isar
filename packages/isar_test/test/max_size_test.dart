import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'max_size_test.g.dart';

@collection
class Model {
  Model(this.id);

  final int id;

  final value = '123456789' * 1000;
}

void main() {
  group('Max Size', () {
    isarTest('default', () async {
      final isar = await openTempIsar([ModelSchema]);
      isar.write((isar) {
        isar.models.putAll(List.generate(1000, Model.new));
      });
    });

    isarTest('10MB', sqlite: false, web: false, () async {
      final isar = await openTempIsar([ModelSchema], maxSizeMiB: 10);

      expect(
        () => isar.write((isar) {
          isar.models.putAll(List.generate(1000, Model.new));
        }),
        throwsA(isA<DatabaseFullError>()),
      );

      isar.write((isar) {
        isar.models.putAll(List.generate(50, Model.new));
      });
    });
  });
}
