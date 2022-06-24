import 'dart:async';
import 'dart:html';

import '../../isar.dart';

import 'bindings.dart';
import 'isar_web.dart';

const Symbol _zoneTxn = #zoneTxn;

class IsarImpl extends Isar {
  IsarImpl(super.name, super.schema, this.instance);
  final IsarInstanceJs instance;
  final List<Future<void>> _activeAsyncTxns = [];

  void requireNotInTxn() {
    if (Zone.current[_zoneTxn] != null) {
      // ignore: only_throw_errors
      throw IsarError(
          'Cannot perform this operation from within an active transaction.');
    }
  }

  Future<T> _txn<T>(
      bool write, bool silent, Future<T> Function() callback) async {
    requireOpen();
    requireNotInTxn();

    final Completer<void> completer = Completer<void>();
    _activeAsyncTxns.add(completer.future);

    final IsarTxnJs txn = instance.beginTxn(write);

    final Zone zone = Zone.current.fork(
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
          // ignore: only_throw_errors
          throw IsarUniqueViolationError();
        } else {
          // ignore: only_throw_errors
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
    final IsarTxnJs? currentTxn = Zone.current[_zoneTxn] as IsarTxnJs?;
    if (currentTxn != null) {
      if (write && !currentTxn.write) {
        // ignore: only_throw_errors
        throw IsarError(
            'Operation cannot be performed within a read transaction.');
      }
      return callback(currentTxn);
    } else if (!write) {
      return _txn(false, false, () {
        return callback(Zone.current[_zoneTxn] as IsarTxnJs);
      });
    } else {
      // ignore: only_throw_errors
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    requireOpen();
    requireNotInTxn();
    await Future.wait(_activeAsyncTxns);
    await super.close();
    await instance.close(deleteFromDisk).wait<dynamic>();
    return true;
  }
}
