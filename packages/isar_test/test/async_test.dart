import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'async_test.g.dart';

@collection
class Model {
  const Model(this.id, this.value);

  final int id;

  final String value;
}

void main() async {
  group('Async', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
    });

    // TODO enable once native assets are supported
    /*isarTest('Open', () async {
      final isarName = isar.name;
      final isarDir = isar.directory;

      isar.write((isar) {
        isar.models.put(const Model(1, 'abc'));
      });
      expect(isar.close(), true);

      if (isSQLite) {
        isar = await Isar.openSQLiteAsync(
          schemas: [ModelSchema],
          name: isarName,
          directory: isarDir,
        );
      } else {
        isar = await Isar.openAsync(
          schemas: [ModelSchema],
          name: isarName,
          directory: isarDir,
        );
      }

      expect(isar.models.get(2), const Model(1, 'abc'));
      expect(isar.close(), true);
    });*/

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
