import 'dart:async';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'transaction_test.g.dart';

@collection
class Model {
  Id? id;
}

void main() {
  group('Transaction', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([ModelSchema]);
    });

    isarTest('Sync txn cannot be opened in sync txn', () {
      isar.txnSync(() {
        expect(
          () => isar.txnSync(() {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxnSync(() {}),
          throwsIsarError('within an active transaction'),
        );
      });

      isar.writeTxnSync(() {
        expect(
          () => isar.txnSync(() {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxnSync(() {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('Sync txn cannot be opened in async txn', () async {
      await isar.txn(() async {
        expect(
          () => isar.txnSync(() {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxnSync(() {}),
          throwsIsarError('within an active transaction'),
        );
      });

      await isar.writeTxn(() async {
        expect(
          () => isar.txnSync(() {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxnSync(() {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('Async txn cannot be opened in sync txn', () {
      isar.txnSync(() {
        expect(
          () => isar.txn(() async {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn(() async {}),
          throwsIsarError('within an active transaction'),
        );
      });

      isar.writeTxnSync(() {
        expect(
          () => isar.txn(() async {}),
          throwsIsarError('within an active transaction'),
        );

        expect(
          () => isar.writeTxn(() async {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('Async txn cannot be opened in async txn', () async {
      await isar.txn(() async {
        await expectLater(
          () => isar.txn(() async {}),
          throwsIsarError('within an active transaction'),
        );

        await expectLater(
          () => isar.writeTxn(() async {}),
          throwsIsarError('within an active transaction'),
        );
      });

      await isar.writeTxn(() async {
        await expectLater(
          () => isar.txn(() async {}),
          throwsIsarError('within an active transaction'),
        );

        await expectLater(
          () => isar.writeTxn(() async {}),
          throwsIsarError('within an active transaction'),
        );
      });
    });

    isarTest('Sync txn can be opened during async write txn', () async {
      final c = Completer<void>();
      final txnFuture = isar.writeTxn(() async {
        await c.future;
      });

      isar.txnSync(() {
        c.complete(null);
      });

      await txnFuture;
    });

    isarTest('Sync write txn cannot be opened during async write txn',
        () async {
      final c = Completer<void>();
      final txnFuture = isar.writeTxn(() async {
        await c.future;
      });

      expect(
        () => isar.writeTxnSync(() {}),
        throwsIsarError('write transaction is already in progress'),
      );

      c.complete();
      await txnFuture;
    });

    isarTest('Async write txn can be opened during async write txn', () async {
      final c = Completer<void>();
      final _ = isar.writeTxn(() async {
        await c.future;
      });

      final txnFuture = isar.writeTxn(() async {});

      c.complete();
      await txnFuture;
    });

    isarTest('Sync writing requires sync write txn', () async {
      expect(
        () => isar.models.putSync(Model()),
        throwsIsarError('require an explicit transaction'),
      );

      await isar.writeTxn(() async {
        expect(
          () => isar.models.putSync(Model()),
          throwsIsarError('require an explicit transaction'),
        );
      });
    });

    isarTest('Async writing requires async write txn', () async {
      await expectLater(
        () => isar.models.put(Model()),
        throwsIsarError('require an explicit transaction'),
      );

      isar.writeTxnSync(() {
        expect(
          () => isar.models.put(Model()),
          throwsIsarError('require an explicit transaction'),
        );
      });
    });
  });
}
