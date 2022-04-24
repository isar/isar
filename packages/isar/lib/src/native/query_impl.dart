import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';

typedef QueryDeserialize<T> = List<T> Function(RawObjectSet);

class QueryImpl<T> extends Query<T> {
  static const maxLimit = 4294967295;

  final IsarCollectionImpl col;
  final Pointer<NativeType> queryPtr;
  final QueryDeserialize<T> deserialize;
  final int? propertyId;

  QueryImpl(this.col, this.queryPtr, this.deserialize, this.propertyId);

  @override
  Future<T?> findFirst() {
    return findInternal(maxLimit).then((result) {
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
    return col.isar.getTxn(false, (txn) async {
      final resultsPtr = txn.alloc<RawObjectSet>();
      try {
        IC.isar_q_find(queryPtr, txn.ptr, resultsPtr, limit);
        await txn.wait();
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
  }

  @override
  T? findFirstSync() {
    final results = findSyncInternal(1);
    if (results.isNotEmpty) {
      return results[0];
    } else {
      return null;
    }
  }

  @override
  List<T> findAllSync() => findSyncInternal(maxLimit);

  List<T> findSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (txn) {
      final resultsPtr = txn.allocRawObjectsSet();
      try {
        nCall(IC.isar_q_find(queryPtr, txn.ptr, resultsPtr, limit));
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() => deleteInternal(1).then((count) => count == 1);

  @override
  Future<int> deleteAll() => deleteInternal(maxLimit);

  Future<int> deleteInternal(int limit) {
    return col.isar.getTxn(false, (txn) async {
      final countPtr = txn.alloc<Uint32>();
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
    return col.isar.getTxnSync(false, (txn) {
      final countPtr = txn.alloc<Uint32>();
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
    final port = ReceivePort();
    final handle = IC.isar_watch_query(
        col.isar.ptr, col.ptr, queryPtr, port.sendPort.nativePort);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    if (initialReturn) {
      controller.add(true);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) {
    return col.isar.getTxn(false, (txn) async {
      final bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final lengthPtr = txn.alloc<Uint32>();
      final idNamePtr = col.schema.idName.toNativeUtf8(allocator: txn.alloc);
      nCall(IC.isar_q_export_json(queryPtr, col.ptr, txn.ptr, idNamePtr.cast(),
          bytesPtrPtr, lengthPtr));

      try {
        await txn.wait();
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
      }
    });
  }

  @override
  R exportJsonRawSync<R>(R Function(Uint8List) callback) {
    return col.isar.getTxnSync(false, (txn) {
      final bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final lengthPtr = txn.alloc<Uint32>();
      final idNamePtr = col.schema.idName.toNativeUtf8(allocator: txn.alloc);

      try {
        nCall(IC.isar_q_export_json(queryPtr, col.ptr, txn.ptr,
            idNamePtr.cast(), bytesPtrPtr, lengthPtr));
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
      }
    });
  }

  @override
  Future<R?> aggregate<R>(AggregationOp op) async {
    return col.isar.getTxn(false, (txn) async {
      final resultPtrPtr = txn.alloc<Pointer>();

      IC.isar_q_aggregate(
          col.ptr, queryPtr, txn.ptr, op.index, propertyId ?? 0, resultPtrPtr);
      await txn.wait();

      return _convertAggregatedResult<R>(resultPtrPtr.value, op);
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) {
    return col.isar.getTxnSync(false, (txn) {
      final resultPtrPtr = txn.alloc<Pointer>();

      nCall(IC.isar_q_aggregate(
          col.ptr, queryPtr, txn.ptr, op.index, propertyId ?? 0, resultPtrPtr));
      return _convertAggregatedResult(resultPtrPtr.value, op);
    });
  }

  R? _convertAggregatedResult<R>(Pointer resultPtr, AggregationOp op) {
    final nullable = op == AggregationOp.min || op == AggregationOp.max;
    if (R == int || R == DateTime) {
      final value = IC.isar_q_aggregate_long_result(resultPtr);
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
      final value = IC.isar_q_aggregate_double_result(resultPtr);
      if (nullable && value.isNaN) {
        return null;
      } else {
        return value as R;
      }
    }
  }
}
