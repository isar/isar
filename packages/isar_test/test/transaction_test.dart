// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'transaction_test.g.dart';

@collection
class Model {
  Model([this.id = Isar.autoIncrement]);

  Id? id;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => other is Model && id == other.id;
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

    isarTest('gets reverted on error', () async {
      await isar.tWriteTxn(() => isar.models.tPut(Model()));
      await qEqual(isar.models.where(), [Model(1)]);

      Future<void> errorTxn() async {
        await isar.tWriteTxn(() async {
          await isar.models.tPut(Model(5));
          await qEqual(isar.models.where(), [Model(1), Model(5)]);
          throw UnsupportedError('test');
        });
      }

      await expectLater(errorTxn(), throwsUnsupportedError);
      await qEqual(isar.models.where(), [Model(1)]);

      await expectLater(errorTxn(), throwsUnsupportedError);
      await qEqual(isar.models.where(), [Model(1)]);

      await isar.tWriteTxn(() => isar.models.tPut(Model(5)));
      await qEqual(isar.models.where(), [Model(1), Model(5)]);
    });
  });
}
