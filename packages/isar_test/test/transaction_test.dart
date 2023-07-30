// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'transaction_test.g.dart';

@collection
class Model {
  Model(this.id);

  int id;

  @override
  bool operator ==(Object other) => other is Model && id == other.id;
}

void main() {
  group('Transaction', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
    });

    isarTest('Sync txn cannot be opened in sync txn', () {
      isar.read((isar) {
        expect(() => isar.read((_) {}), throwsUnsupportedError);
        expect(() => isar.write((_) {}), throwsUnsupportedError);
      });

      isar.write((isar) {
        expect(() => isar.read((_) {}), throwsUnsupportedError);
        expect(() => isar.write((_) {}), throwsUnsupportedError);
      });
    });

    isarTest('Asyc txn cannot be opened in sync txn', () async {
      isar.read((isar) {
        expect(() => isar.readAsync((_) {}), throwsUnsupportedError);
        expect(
          () => isar.readAsyncWith<void, void>(null, (_, __) {}),
          throwsUnsupportedError,
        );
        expect(() => isar.writeAsync((_) {}), throwsUnsupportedError);
        expect(
          () => isar.writeAsyncWith<void, void>(null, (_, __) {}),
          throwsUnsupportedError,
        );
      });

      isar.write((isar) {
        expect(() => isar.readAsync((_) {}), throwsUnsupportedError);
        expect(
          () => isar.readAsyncWith<void, void>(null, (_, __) {}),
          throwsUnsupportedError,
        );
        expect(() => isar.writeAsync((_) {}), throwsUnsupportedError);
        expect(
          () => isar.writeAsyncWith<void, void>(null, (_, __) {}),
          throwsUnsupportedError,
        );
      });
    });

    isarTest('gets reverted on error', () {
      isar.write((isar) => isar.models.put(Model(1)));
      expect(isar.models.where().findAll(), [Model(1)]);

      void errorTxn() {
        isar.write((isar) {
          isar.models.put(Model(5));
          expect(isar.models.where().findAll(), [Model(1), Model(5)]);
          throw UnsupportedError('test');
        });
      }

      expect(errorTxn, throwsUnsupportedError);
      expect(isar.models.where().findAll(), [Model(1)]);

      expectLater(errorTxn, throwsUnsupportedError);
      expect(isar.models.where().findAll(), [Model(1)]);

      isar.write((isar) => isar.models.put(Model(5)));
      expect(isar.models.where().findAll(), [Model(1), Model(5)]);
    });
  });
}
