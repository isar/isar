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
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is Model && id == other.id;
}

void main() {
  group('Transaction', () {
    late Isar isar;

    setUp(() {
      isar = openTempIsar([ModelSchema]);
    });

    isarTest('Sync txn cannot be opened in sync txn', () {
      isar.txn((isar) {
        expect(
          () => isar.txn((_) {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn((_) {}),
          throwsIsarError('within an active transaction'),
        );
      });

      isar.writeTxn((isar) {
        expect(
          () => isar.txn((_) {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn((_) {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('Sync txn cannot be opened in async txn', () async {
      await isar.txnAsync((isar) {
        expect(
          () => isar.txn((_) {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn((_) {}),
          throwsIsarError('within an active transaction'),
        );
      });

      await isar.writeTxnAsync((isar) {
        expect(
          () => isar.txn((_) {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn((_) {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('gets reverted on error', () {
      isar.writeTxn((isar) => isar.models.put(Model(1)));
      expect(isar.models.where().findAll(), [Model(1)]);

      void errorTxn() {
        isar.writeTxn((isar) {
          isar.models.put(Model(5));
          expect(isar.models.where().findAll(), [Model(1), Model(5)]);
          throw UnsupportedError('test');
        });
      }

      expect(errorTxn, throwsUnsupportedError);
      expect(isar.models.where().findAll(), [Model(1)]);

      expectLater(errorTxn, throwsUnsupportedError);
      expect(isar.models.where().findAll(), [Model(1)]);

      isar.writeTxn((isar) => isar.models.put(Model(5)));
      expect(isar.models.where().findAll(), [Model(1), Model(5)]);
    });
  });
}
