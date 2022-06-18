import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../../isar.dart';
import 'bindings.dart';
import 'isar_core.dart';

const Symbol _zoneTxn = #zoneTxn;

class IsarImpl extends Isar implements Finalizable {
  IsarImpl(super.name, super.schema, this.ptr) {
    _finalizer = NativeFinalizer(isarClose);
    _finalizer.attach(this, ptr.cast(), detach: this);
  }
  final Pointer<CIsarInstance> ptr;
  late final NativeFinalizer _finalizer;

  final List<Future<void>> _activeAsyncTxns = [];

  final Pointer<Pointer<CIsarTxn>> _syncTxnPtrPtr = malloc<Pointer<CIsarTxn>>();
  SyncTxn? _currentTxnSync;

  void requireNotInTxn() {
    if (_currentTxnSync != null || Zone.current[_zoneTxn] != null) {
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

    final ReceivePort port = ReceivePort();
    final Stream<void> portStream = wrapIsarPort(port);

    final Pointer<Pointer<CIsarTxn>> txnPtrPtr = malloc<Pointer<CIsarTxn>>();
    IC.isar_txn_begin(
        ptr, txnPtrPtr, false, write, silent, port.sendPort.nativePort);

    Txn txn;
    try {
      await portStream.first;
      txn = Txn._(txnPtrPtr.value, write, portStream);
    } finally {
      malloc.free(txnPtrPtr);
    }

    final Zone zone = Zone.current.fork(
      zoneValues: {_zoneTxn: txn},
    );

    T result;
    try {
      result = await zone.run(callback);
      IC.isar_txn_finish(txn.ptr, true);
      await txn.wait();
    } catch (e) {
      IC.isar_txn_finish(txn.ptr, false);
      rethrow;
    } finally {
      txn.free();
      port.close();
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

  Future<T> getTxn<T>(bool write, Future<T> Function(Txn txn) callback) {
    final Txn? currentTxn = Zone.current[_zoneTxn] as Txn?;
    if (currentTxn != null) {
      if (write && !currentTxn.write) {
        // ignore: only_throw_errors
        throw IsarError(
            'Operation cannot be performed within a read transaction.');
      }
      return callback(currentTxn);
    } else if (!write) {
      return _txn(false, false, () {
        return callback(Zone.current[_zoneTxn] as Txn);
      });
    } else {
      // ignore: only_throw_errors
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  T _txnSync<T>(bool write, bool silent, T Function() callback) {
    requireOpen();
    requireNotInTxn();

    nCall(IC.isar_txn_begin(ptr, _syncTxnPtrPtr, true, write, silent, 0));
    final SyncTxn txn = SyncTxn._(_syncTxnPtrPtr.value, write);
    _currentTxnSync = txn;

    T result;
    try {
      result = callback();
      nCall(IC.isar_txn_finish(txn.ptr, true));
    } catch (e) {
      IC.isar_txn_finish(txn.ptr, false);
      rethrow;
    } finally {
      _currentTxnSync = null;
      txn.free();
    }

    return result;
  }

  @override
  T txnSync<T>(T Function() callback) {
    return _txnSync(false, false, callback);
  }

  @override
  T writeTxnSync<T>(T Function() callback, {bool silent = false}) {
    return _txnSync(true, silent, callback);
  }

  T getTxnSync<T>(bool write, T Function(SyncTxn txn) callback) {
    if (_currentTxnSync != null) {
      if (write && !_currentTxnSync!.write) {
        // ignore: only_throw_errors
        throw IsarError(
            'Operation cannot be performed within a read transaction.');
      }
      return callback(_currentTxnSync!);
    } else if (!write) {
      return _txnSync(false, false, () => callback(_currentTxnSync!));
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

    _finalizer.detach(this);
    if (deleteFromDisk) {
      return IC.isar_close_delete_instance(ptr);
    } else {
      return IC.isar_close_instance(ptr);
    }
  }
}

class SyncTxn {
  SyncTxn._(this.ptr, this.write);
  final Pointer<CIsarTxn> ptr;

  final bool write;

  final Arena alloc = Arena(malloc);

  // ignore: use_late_for_private_fields_and_variables
  Pointer<CObject>? _cObjsPtr;
  int _cObjsLen = -1;

  Pointer<CObjectSet>? _cObjSetPtr;

  // ignore: use_late_for_private_fields_and_variables
  Pointer<Uint8>? _buffer;
  int _bufferLen = -1;

  Pointer<CObject> allocCObject() {
    if (_cObjsLen < 1) {
      _cObjsPtr = alloc();
      _cObjsLen = 1;
    }
    return _cObjsPtr!;
  }

  Pointer<CObjectSet> allocCObjectsSet() {
    _cObjSetPtr ??= alloc();
    return _cObjSetPtr!;
  }

  Pointer<Uint8> allocBuffer(int size) {
    if (_bufferLen < size) {
      _buffer = alloc(size);
      _bufferLen = size;
    }
    return _buffer!;
  }

  void free() {
    alloc.releaseAll();
  }
}

class Txn {
  Txn._(this.ptr, this.write, Stream<void> stream) {
    stream.listen(
      (_) {
        assert(
            _completers.isNotEmpty, 'There should be a completer listening.');
        final Completer<void> completer = _completers.removeFirst();
        completer.complete();
      },
      onError: (dynamic e) {
        assert(
            _completers.isNotEmpty, 'There should be a completer listening.');
        final Completer<void> completer = _completers.removeFirst();
        completer.completeError(e as Object);
      },
    );
  }
  final Pointer<CIsarTxn> ptr;

  final bool write;

  final Arena alloc = Arena(malloc);

  final Queue<Completer<void>> _completers = Queue<Completer<void>>();

  Future<void> wait() {
    final Completer<void> completer = Completer<void>();
    _completers.add(completer);
    return completer.future;
  }

  Pointer<CObjectSet> allocCObjectSet(int length) {
    final Pointer<CObjectSet> cObjSetPtr = alloc<CObjectSet>();
    cObjSetPtr.ref
      ..objects = alloc<CObject>(length)
      ..length = length;
    return cObjSetPtr;
  }

  void free() {
    alloc.releaseAll();
  }
}
