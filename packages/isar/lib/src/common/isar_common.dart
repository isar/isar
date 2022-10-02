// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';

import 'package:isar/isar.dart';

const Symbol _zoneTxn = #zoneTxn;

/// @nodoc
abstract class IsarCommon extends Isar {
  /// @nodoc
  IsarCommon(super.name);

  final List<Future<void>> _activeAsyncTxns = [];
  var _asyncWriteTxnsActive = 0;

  Transaction? _currentTxnSync;

  void _requireNotInTxn() {
    if (_currentTxnSync != null || Zone.current[_zoneTxn] != null) {
      throw IsarError(
        'Cannot perform this operation from within an active transaction.',
      );
    }
  }

  /// @nodoc
  Future<Transaction> beginTxn(bool write, bool silent);

  Future<T> _beginTxn<T>(
    bool write,
    bool silent,
    Future<T> Function() callback,
  ) async {
    requireOpen();
    _requireNotInTxn();

    final completer = Completer<void>();
    _activeAsyncTxns.add(completer.future);

    try {
      if (write) {
        _asyncWriteTxnsActive++;
      }

      final txn = await beginTxn(write, silent);

      final zone = Zone.current.fork(
        zoneValues: {_zoneTxn: txn},
      );

      T result;
      try {
        result = await zone.run(callback);
        await txn.commit();
      } catch (e) {
        await txn.abort();
        rethrow;
      } finally {
        txn.free();
      }
      return result;
    } finally {
      completer.complete();
      _activeAsyncTxns.remove(completer.future);
      if (write) {
        _asyncWriteTxnsActive--;
      }
    }
  }

  @override
  Future<T> txn<T>(Future<T> Function() callback) {
    return _beginTxn(false, false, callback);
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function() callback, {bool silent = false}) {
    return _beginTxn(true, silent, callback);
  }

  /// @nodoc
  Future<R> getTxn<R, T extends Transaction>(
    bool write,
    Future<R> Function(T txn) callback,
  ) {
    final currentTxn = Zone.current[_zoneTxn] as T?;
    if (currentTxn != null) {
      if (write && !currentTxn.write) {
        throw IsarError(
          'Operation cannot be performed within a read transaction.',
        );
      }
      return callback(currentTxn);
    } else if (!write) {
      return _beginTxn(false, false, () {
        return callback(Zone.current[_zoneTxn] as T);
      });
    } else {
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  /// @nodoc
  Transaction beginTxnSync(bool write, bool silent);

  T _beginTxnSync<T>(bool write, bool silent, T Function() callback) {
    requireOpen();
    _requireNotInTxn();

    if (write && _asyncWriteTxnsActive > 0) {
      throw IsarError(
        'An async write transaction is already in progress in this isolate.',
      );
    }

    final txn = beginTxnSync(write, silent);
    _currentTxnSync = txn;

    T result;
    try {
      result = callback();
      txn.commitSync();
    } catch (e) {
      txn.abortSync();
      rethrow;
    } finally {
      _currentTxnSync = null;
      txn.free();
    }

    return result;
  }

  @override
  T txnSync<T>(T Function() callback) {
    return _beginTxnSync(false, false, callback);
  }

  @override
  T writeTxnSync<T>(T Function() callback, {bool silent = false}) {
    return _beginTxnSync(true, silent, callback);
  }

  /// @nodoc
  R getTxnSync<R, T extends Transaction>(
    bool write,
    R Function(T txn) callback,
  ) {
    if (_currentTxnSync != null) {
      if (write && !_currentTxnSync!.write) {
        throw IsarError(
          'Operation cannot be performed within a read transaction.',
        );
      }
      return callback(_currentTxnSync! as T);
    } else if (!write) {
      return _beginTxnSync(false, false, () => callback(_currentTxnSync! as T));
    } else {
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    requireOpen();
    _requireNotInTxn();
    await Future.wait(_activeAsyncTxns);
    await super.close();

    return performClose(deleteFromDisk);
  }

  /// @nodoc
  bool performClose(bool deleteFromDisk);
}

/// @nodoc
abstract class Transaction {
  /// @nodoc
  Transaction(this.sync, this.write);

  /// @nodoc
  final bool sync;

  /// @nodoc
  final bool write;

  /// @nodoc
  Future<void> commit();

  /// @nodoc
  void commitSync();

  /// @nodoc
  Future<void> abort();

  /// @nodoc
  void abortSync();

  /// @nodoc
  void free() {}
}
