@TestOn('vm')
library;

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'async_test.g.dart';

@collection
class Model {
  const Model(this.id, this.value);

  final int id;

  final String value;

  @override
  bool operator ==(other) =>
      other is Model && id == other.id && value == other.value;
}

void main() async {
  group('Async', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
    });

    isarTest('Open', () async {
      final isarName = isar.name;
      final isarDir = isar.directory;

      isar.write((isar) {
        isar.models.put(const Model(1, 'abc'));
      });
      expect(isar.close(), true);

      final isar2 = await Isar.openAsync(
        schemas: [ModelSchema],
        name: isarName,
        directory: isarDir,
        engine: isSQLite ? IsarEngine.sqlite : IsarEngine.isar,
      );

      expect(isar2.models.get(1), const Model(1, 'abc'));
      expect(isar2.close(), true);
    });

    isarTest('Bulk insert', () async {
      final futures = List.generate(100, (index) {
        return isar.writeAsyncWith(index, (isar, index) {
          isar.models.putAll([
            Model(index * 100 + 1, 'value1'),
            Model(index * 100 + 2, 'value2'),
            Model(index * 100 + 3, 'value3'),
          ]);
        });
      });

      await Future.wait(futures);
    });
  });
}
