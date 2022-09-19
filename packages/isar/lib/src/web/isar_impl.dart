// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:html';

import 'package:isar/isar.dart';

import 'package:isar/src/web/bindings.dart';
import 'package:isar/src/web/isar_web.dart';

const Symbol _zoneTxn = #zoneTxn;

class IsarImpl extends Isar {
  IsarImpl(super.name, this.instance);

  final IsarInstanceJs instance;
  final offsets = <Type, List<int>>{};
  final List<Future<void>> _activeAsyncTxns = [];

  @override
  final String? directory = null;

  void requireNotInTxn() {
    if (Zone.current[_zoneTxn] != null) {
      throw IsarError(
        'Cannot perform this operation from within an active transaction.',
      );
    }
  }

  Future<T> _txn<T>(
    bool write,
    bool silent,
    Future<T> Function() callback,
  ) async {
    requireOpen();
    requireNotInTxn();

    final completer = Completer<void>();
    _activeAsyncTxns.add(completer.future);

    final txn = instance.beginTxn(write);

    final zone = Zone.current.fork(
      zoneValues: {_zoneTxn: txn},
    );

    T result;
    try {
      result = await zone.run(callback);
      await txn.commit().wait<dynamic>();
    } catch (e) {
      txn.abort();
      if (e is DomException) {
        if (e.name == DomException.CONSTRAINT) {
          throw IsarUniqueViolationError();
        } else {
          throw IsarError('${e.name}: ${e.message}');
        }
      } else {
        rethrow;
      }
    } finally {
      completer.complete();
      _activeAsyncTxns.remove(completer.future);
    }

    return result;
  }

  @override
  Future<T> txn<T>(Future<T> Function() callback) {
    return _txn(false, false, callback);
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return _txn(true, silent, callback);
  }

  @override
  T txnSync<T>(T Function() callback) => unsupportedOnWeb();

  @override
  T writeTxnSync<T>(T Function() callback, {bool silent = false}) =>
      unsupportedOnWeb();

  Future<T> getTxn<T>(bool write, Future<T> Function(IsarTxnJs txn) callback) {
    final currentTxn = Zone.current[_zoneTxn] as IsarTxnJs?;
    if (currentTxn != null) {
      if (write && !currentTxn.write) {
        throw IsarError(
          'Operation cannot be performed within a read transaction.',
        );
      }
      return callback(currentTxn);
    } else if (!write) {
      return _txn(false, false, () {
        return callback(Zone.current[_zoneTxn] as IsarTxnJs);
      });
    } else {
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  int getSizeSync({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) =>
      unsupportedOnWeb();

  @override
  Future<void> copyToFile(String targetPath) => unsupportedOnWeb();

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    requireOpen();
    requireNotInTxn();
    await Future.wait(_activeAsyncTxns);
    await super.close();
    await instance.close(deleteFromDisk).wait<dynamic>();
    return true;
  }

  @override
  Future<void> verify() => unsupportedOnWeb();
}
