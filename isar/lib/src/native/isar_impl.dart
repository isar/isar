import 'dart:async';
import 'dart:ffi';

import 'package:isar/src/isar.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/util/native_call.dart';

const zoneTxn = #zoneTxn;
const zoneTxnWrite = #zoneTxnWrite;

class IsarImpl extends Isar {
  final Pointer isarPtr;

  Pointer? _currentTxnSync;
  bool _currentTxnSyncWrite = false;

  IsarImpl(this.isarPtr);

  @override
  Future<T> txn<T>(Future<T> Function(Isar isar) callback) async {
    if (Zone.current[zoneTxn] != null) {
      throw 'Nested transactions are not supported yet.';
    }
    throw '';
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback) async {
    if (Zone.current[zoneTxn] != null) {
      throw 'Nested transactions are not supported yet.';
    }
    throw '';
  }

  T _txnSync<T>(bool write, T Function(Isar isar) callback) {
    if (_currentTxnSync != null || Zone.current[zoneTxn] != null) {
      throw 'Nested transactions are not supported.';
    }
    var txnPtr = IsarCoreUtils.syncTxnPtr;
    nativeCall(IsarCore.isar_txn_begin(isarPtr, txnPtr, write));
    var txn = txnPtr.value;
    _currentTxnSync = txn;
    _currentTxnSyncWrite = write;

    T result;
    try {
      result = callback(this);
    } catch (e) {
      _currentTxnSync = null;
      IsarCore.isar_txn_abort(txn);
      rethrow;
    }

    _currentTxnSync = null;
    nativeCall(IsarCore.isar_txn_commit(txn));

    return result;
  }

  @override
  T txnSync<T>(T Function(Isar isar) callback) {
    return _txnSync(false, callback);
  }

  @override
  T writeTxnSync<T>(T Function(Isar isar) callback) {
    return _txnSync(true, callback);
  }

  Future<T> optionalTxn<T>(bool write, T Function(Pointer txn) callback) {
    throw UnimplementedError();
  }

  Pointer? getTxnSync(bool write) {
    if (_currentTxnSync != null) {
      if (write && !_currentTxnSyncWrite) {
        throw 'Operation cannot be performed within a read transaction.';
      }
      if (Zone.current[zoneTxn] != null) {
        throw 'Operation cannot be performed within an async transaction.';
      }
      return _currentTxnSync;
    }
    return null;
  }
}
