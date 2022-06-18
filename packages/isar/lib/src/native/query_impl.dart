import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import '../../isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'isar_impl.dart';

typedef QueryDeserialize<T> = List<T> Function(CObjectSet);

class QueryImpl<T> extends Query<T> implements Finalizable {

  QueryImpl(this.col, this.queryPtr, this.deserialize, this.propertyId) {
    NativeFinalizer(isarQueryFree).attach(this, queryPtr.cast());
  }
  static const int maxLimit = 4294967295;

  final IsarCollectionImpl<dynamic> col;
  final Pointer<CQuery> queryPtr;
  final QueryDeserialize<T> deserialize;
  final int? propertyId;

  @override
  Isar get isar => col.isar;

  @override
  Future<T?> findFirst() {
    return findInternal(maxLimit).then((List<T> result) {
      if (result.isNotEmpty) {
        return result[0];
      } else {
        return null;
      }
    });
  }

  @override
  Future<List<T>> findAll() => findInternal(maxLimit);

  Future<List<T>> findInternal(int limit) {
    return col.isar.getTxn(false, (Txn txn) async {
      final Pointer<CObjectSet> resultsPtr = txn.alloc<CObjectSet>();
      try {
        IC.isar_q_find(queryPtr, txn.ptr, resultsPtr, limit);
        await txn.wait();
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_c_object_set(resultsPtr);
      }
    });
  }

  @override
  T? findFirstSync() {
    final List<T> results = findSyncInternal(1);
    if (results.isNotEmpty) {
      return results[0];
    } else {
      return null;
    }
  }

  @override
  List<T> findAllSync() => findSyncInternal(maxLimit);

  List<T> findSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (SyncTxn txn) {
      final Pointer<CObjectSet> resultsPtr = txn.allocCObjectsSet();
      try {
        nCall(IC.isar_q_find(queryPtr, txn.ptr, resultsPtr, limit));
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_c_object_set(resultsPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() => deleteInternal(1).then((int count) => count == 1);

  @override
  Future<int> deleteAll() => deleteInternal(maxLimit);

  Future<int> deleteInternal(int limit) {
    return col.isar.getTxn(false, (Txn txn) async {
      final Pointer<Uint32> countPtr = txn.alloc<Uint32>();
      IC.isar_q_delete(queryPtr, col.ptr, txn.ptr, limit, countPtr);
      await txn.wait();
      return countPtr.value;
    });
  }

  @override
  bool deleteFirstSync() => deleteSyncInternal(1) == 1;

  @override
  int deleteAllSync() => deleteSyncInternal(maxLimit);

  int deleteSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (SyncTxn txn) {
      final Pointer<Uint32> countPtr = txn.alloc<Uint32>();
      nCall(IC.isar_q_delete(queryPtr, col.ptr, txn.ptr, limit, countPtr));
      return countPtr.value;
    });
  }

  @override
  Stream<List<T>> watch({bool initialReturn = false}) {
    return watchLazy(initialReturn: initialReturn)
        .asyncMap((event) => findAll());
  }

  @override
  Stream<void> watchLazy({bool initialReturn = false}) {
    final ReceivePort port = ReceivePort();
    final Pointer<CWatchHandle> handle = IC.isar_watch_query(
        col.isar.ptr, col.ptr, queryPtr, port.sendPort.nativePort);

    final StreamController<void> controller = StreamController<void>(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    if (initialReturn) {
      controller.add(null);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) {
    return col.isar.getTxn(false, (Txn txn) async {
      final Pointer<Pointer<Uint8>> bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final Pointer<Uint32> lengthPtr = txn.alloc<Uint32>();
      final Pointer<Utf8> idNamePtr = col.schema.idName.toNativeUtf8(allocator: txn.alloc);
      nCall(IC.isar_q_export_json(queryPtr, col.ptr, txn.ptr, idNamePtr.cast(),
          bytesPtrPtr, lengthPtr));

      try {
        await txn.wait();
        final Uint8List bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
      }
    });
  }

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback) {
    return col.isar.getTxnSync(false, (SyncTxn txn) {
      final Pointer<Pointer<Uint8>> bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final Pointer<Uint32> lengthPtr = txn.alloc<Uint32>();
      final Pointer<Utf8> idNamePtr = col.schema.idName.toNativeUtf8(allocator: txn.alloc);

      try {
        nCall(IC.isar_q_export_json(queryPtr, col.ptr, txn.ptr,
            idNamePtr.cast(), bytesPtrPtr, lengthPtr));
        final Uint8List bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
      }
    });
  }

  @override
  Future<R?> aggregate<R>(AggregationOp op) async {
    return col.isar.getTxn(false, (Txn txn) async {
      final Pointer<Pointer<CAggregationResult>> resultPtrPtr = txn.alloc<Pointer<CAggregationResult>>();

      IC.isar_q_aggregate(
          col.ptr, queryPtr, txn.ptr, op.index, propertyId ?? 0, resultPtrPtr);
      await txn.wait();

      return _convertAggregatedResult<R>(resultPtrPtr.value, op);
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) {
    return col.isar.getTxnSync(false, (SyncTxn txn) {
      final Pointer<Pointer<CAggregationResult>> resultPtrPtr = txn.alloc<Pointer<CAggregationResult>>();

      nCall(IC.isar_q_aggregate(
          col.ptr, queryPtr, txn.ptr, op.index, propertyId ?? 0, resultPtrPtr));
      return _convertAggregatedResult(resultPtrPtr.value, op);
    });
  }

  R? _convertAggregatedResult<R>(
      Pointer<CAggregationResult> resultPtr, AggregationOp op) {
    final bool nullable = op == AggregationOp.min || op == AggregationOp.max;
    if (R == int || R == DateTime) {
      final int value = IC.isar_q_aggregate_long_result(resultPtr);
      if (nullable && value == nullLong) {
        return null;
      }
      if (R == int) {
        return value as R;
      } else {
        return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal()
            as R;
      }
    } else {
      final double value = IC.isar_q_aggregate_double_result(resultPtr);
      if (nullable && value.isNaN) {
        return null;
      } else {
        return value as R;
      }
    }
  }
}
