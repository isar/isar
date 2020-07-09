import 'dart:ffi';

import 'package:isar/src/isar.dart';
import 'package:isar/src/native/bindings/bindings.dart';
import 'package:isar/src/native/util/native_call.dart';

class IsarImpl extends Isar {
  final Pointer isarPtr;

  Pointer _currentTxn;
  bool _currentTxnWrite = false;

  IsarImpl(this.isarPtr);

  @override
  Future<T> txn<T>(bool write, Future<T> Function(Isar isar) callback) async {
    if (_currentTxn != null) {
      throw "Nested transactions are not supported yet.";
    }
    var txnPtr = IsarBindings.ptr;
    nativeCall(isarBindings.beginTxn(isarPtr, txnPtr, nBool(write)));
    var txn = txnPtr.value;
    _currentTxn = txn;
    _currentTxnWrite = write;

    T result;
    try {
      result = await callback(this);
    } catch (e) {
      _currentTxn = null;
      nativeCall(isarBindings.abortTxn(txn));
      rethrow;
    }

    _currentTxn = null;
    nativeCall(isarBindings.commitTxn(txn));

    return result;
  }

  Future<T> optionalTxn<T>(bool write, T Function(Pointer txn) callback) {
    if (_currentTxn != null) {
      if (write && !_currentTxnWrite) {
        throw "Operation cannot be performed within a read transaction.";
      }
      return Future.value(callback(_currentTxn));
    } else {
      return txn(write, (_) => Future.value(callback(_currentTxn)));
    }
  }
}
