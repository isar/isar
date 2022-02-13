import 'dart:async';
import 'dart:collection';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'isar_core.dart';
import 'bindings.dart';

const _zoneTxn = #zoneTxn;

class IsarImpl extends Isar {
  final Pointer ptr;

  final List<Future> _activeAsyncTxns = [];

  final _syncTxnPtrPtr = malloc<Pointer>();
  SyncTxn? _currentTxnSync;

  IsarImpl(String name, String schema, this.ptr) : super(name, schema);

  void requireNotInTxn() {
    if (_currentTxnSync != null || Zone.current[_zoneTxn] != null) {
      throw IsarError(
          'Cannot perform this operation from within an active transaction.');
    }
  }

  Future<T> _txn<T>(
      bool write, bool silent, Future<T> Function(Isar isar) callback) async {
    requireOpen();
    requireNotInTxn();

    final completer = Completer();
    _activeAsyncTxns.add(completer.future);

    final port = ReceivePort();
    final portStream = wrapIsarPort(port);

    final txnPtrPtr = malloc<Pointer<NativeType>>();
    IC.isar_txn_begin(
        ptr, txnPtrPtr, false, write, silent, port.sendPort.nativePort);

    Txn txn;
    try {
      await portStream.first;
      txn = Txn._(txnPtrPtr.value, write, portStream);
    } finally {
      malloc.free(txnPtrPtr);
    }

    final zone = Zone.current.fork(
      zoneValues: {_zoneTxn: txn},
    );

    T result;
    try {
      result = await zone.run(() => callback(this));
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
  Future<T> txn<T>(Future<T> Function(Isar isar) callback) {
    return _txn(false, false, callback);
  }

  @override
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback,
      {bool silent = false}) {
    return _txn(true, silent, callback);
  }

  Future<T> getTxn<T>(bool write, Future<T> Function(Txn txn) callback) {
    Txn? currentTxn = Zone.current[_zoneTxn];
    if (currentTxn != null) {
      if (write && !currentTxn.write) {
        throw IsarError(
            'Operation cannot be performed within a read transaction.');
      }
      return callback(currentTxn);
    } else if (!write) {
      return _txn(false, false, (isar) {
        return callback(Zone.current[_zoneTxn]);
      });
    } else {
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  T _txnSync<T>(bool write, bool silent, T Function(Isar isar) callback) {
    requireOpen();
    requireNotInTxn();

    nCall(IC.isar_txn_begin(ptr, _syncTxnPtrPtr, true, write, silent, 0));
    final txn = SyncTxn._(_syncTxnPtrPtr.value, write);
    _currentTxnSync = txn;

    T result;
    try {
      result = callback(this);
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
  T txnSync<T>(T Function(Isar isar) callback) {
    return _txnSync(false, false, callback);
  }

  @override
  T writeTxnSync<T>(T Function(Isar isar) callback, {bool silent = false}) {
    return _txnSync(true, silent, callback);
  }

  T getTxnSync<T>(bool write, T Function(SyncTxn txn) callback) {
    if (_currentTxnSync != null) {
      if (write && !_currentTxnSync!.write) {
        throw IsarError(
            'Operation cannot be performed within a read transaction.');
      }
      return callback(_currentTxnSync!);
    } else if (!write) {
      return _txnSync(false, false, (isar) => callback(_currentTxnSync!));
    } else {
      throw IsarError('Write operations require an explicit transaction.');
    }
  }

  @override
  Future<bool> close({bool deleteFromDisk = false}) async {
    requireOpen();
    requireNotInTxn();
    await Future.wait(_activeAsyncTxns);
    await super.close();
    return IC.isar_close_instance(ptr, deleteFromDisk);
  }
}

class SyncTxn {
  final Pointer ptr;

  final bool write;

  final alloc = Arena(malloc);

  SyncTxn._(this.ptr, this.write);

  Pointer<RawObject>? _rawObjsPtr;
  var _rawObjsLen = -1;

  Pointer<RawObjectSet>? _rawObjSetPtr;

  Pointer<Uint8>? _buffer;
  var _bufferLen = -1;

  Pointer<RawObject> allocRawObject() {
    if (_rawObjsLen < 1) {
      _rawObjsPtr = alloc();
      _rawObjsLen = 1;
    }
    return _rawObjsPtr!;
  }

  Pointer<RawObjectSet> allocRawObjectsSet() {
    _rawObjSetPtr ??= alloc();
    return _rawObjSetPtr!;
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
  final Pointer ptr;

  final bool write;

  final alloc = Arena(malloc);

  final _completers = Queue<Completer>();

  Txn._(this.ptr, this.write, Stream stream) {
    stream.listen(
      (_) {
        assert(
            _completers.isNotEmpty, 'There should be a completer listening.');
        final completer = _completers.removeFirst();
        completer.complete();
      },
      onError: (e) {
        assert(
            _completers.isNotEmpty, 'There should be a completer listening.');
        final completer = _completers.removeFirst();
        completer.completeError(e);
      },
    );
  }

  Future<void> wait() {
    final completer = Completer();
    _completers.add(completer);
    return completer.future;
  }

  Pointer<RawObjectSet> allocRawObjSet(int length) {
    final rawObjSetPtr = malloc<RawObjectSet>();
    rawObjSetPtr.ref
      ..objects = malloc<RawObject>(length)
      ..length = length;
    return rawObjSetPtr;
  }

  void free() {
    alloc.releaseAll();
  }
}
