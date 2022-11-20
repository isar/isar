// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/src/common/isar_common.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/txn.dart';

class IsarImpl extends IsarCommon implements Finalizable {
  IsarImpl(super.name, this.ptr) {
    _finalizer = NativeFinalizer(isarClose);
    _finalizer.attach(this, ptr.cast(), detach: this);
  }

  final Pointer<CIsarInstance> ptr;
  late final NativeFinalizer _finalizer;

  final offsets = <Type, List<int>>{};

  final Pointer<Pointer<CIsarTxn>> _syncTxnPtrPtr = malloc<Pointer<CIsarTxn>>();

  String? _directory;

  @override
  String get directory {
    requireOpen();

    if (_directory == null) {
      final dirPtr = IC.isar_instance_get_path(ptr);
      try {
        _directory = dirPtr.cast<Utf8>().toDartString();
      } finally {
        IC.isar_free_string(dirPtr);
      }
    }

    return _directory!;
  }

  @override
  Future<Transaction> beginTxn(bool write, bool silent) async {
    final port = ReceivePort();
    final portStream = wrapIsarPort(port);

    final txnPtrPtr = malloc<Pointer<CIsarTxn>>();
    IC.isar_txn_begin(
      ptr,
      txnPtrPtr,
      false,
      write,
      silent,
      port.sendPort.nativePort,
    );

    final txn = Txn.async(this, txnPtrPtr.value, write, portStream);
    await txn.wait();
    return txn;
  }

  @override
  Transaction beginTxnSync(bool write, bool silent) {
    nCall(IC.isar_txn_begin(ptr, _syncTxnPtrPtr, true, write, silent, 0));
    return Txn.sync(this, _syncTxnPtrPtr.value, write);
  }

  @override
  bool performClose(bool deleteFromDisk) {
    _finalizer.detach(this);
    if (deleteFromDisk) {
      return IC.isar_instance_close_and_delete(ptr);
    } else {
      return IC.isar_instance_close(ptr);
    }
  }

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) {
    return getTxn(false, (Txn txn) async {
      final sizePtr = txn.alloc<Int64>();
      IC.isar_instance_get_size(
        ptr,
        txn.ptr,
        includeIndexes,
        includeLinks,
        sizePtr,
      );
      await txn.wait();
      return sizePtr.value;
    });
  }

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) {
    return getTxnSync(false, (Txn txn) {
      final sizePtr = txn.alloc<Int64>();
      nCall(
        IC.isar_instance_get_size(
          ptr,
          txn.ptr,
          includeIndexes,
          includeLinks,
          sizePtr,
        ),
      );
      return sizePtr.value;
    });
  }

  @override
  Future<void> copyToFile(String targetPath) async {
    final pathPtr = targetPath.toCString(malloc);
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;

    try {
      final stream = wrapIsarPort(receivePort);
      IC.isar_instance_copy_to_file(ptr, pathPtr, nativePort);
      await stream.first;
    } finally {
      malloc.free(pathPtr);
    }
  }

  @override
  Future<void> verify() async {
    return getTxn(false, (Txn txn) async {
      IC.isar_instance_verify(ptr, txn.ptr);
      await txn.wait();
    });
  }
}
