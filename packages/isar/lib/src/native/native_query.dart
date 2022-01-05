import 'dart:async';
import 'dart:isolate';

import 'package:isar/isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';

typedef QueryDeserialize<T> = List<T> Function(RawObjectSet);

class NativeQuery<T> extends Query<T> {
  static const maxLimit = 4294967295;

  final IsarCollectionImpl col;
  final Pointer<NativeType> queryPtr;
  final QueryDeserialize<T> deserialize;
  final int? propertyId;

  NativeQuery(this.col, this.queryPtr, this.deserialize, this.propertyId);

  @override
  Future<T?> findFirst() {
    return findInternal(maxLimit).then((result) {
      if (result.isNotEmpty) {
        return result[0];
      }
    });
  }

  @override
  Future<List<T>> findAll() => findInternal(maxLimit);

  Future<List<T>> findInternal(int limit) {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        IC.isar_q_find(queryPtr, txnPtr, resultsPtr, limit);
        await stream.first;
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
        malloc.free(resultsPtr);
      }
    });
  }

  @override
  T? findFirstSync() {
    final results = findSyncInternal(1);
    if (results.isNotEmpty) {
      return results[0];
    }
  }

  @override
  List<T> findAllSync() => findSyncInternal(maxLimit);

  List<T> findSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = malloc<RawObjectSet>();
      try {
        nCall(IC.isar_q_find(queryPtr, txnPtr, resultsPtr, limit));
        return deserialize(resultsPtr.ref).cast();
      } finally {
        malloc.free(resultsPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() => deleteInternal(1).then((count) => count == 1);

  @override
  Future<int> deleteAll() => deleteInternal(maxLimit);

  Future<int> deleteInternal(int limit) {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = malloc<Uint32>();
      try {
        IC.isar_q_delete(
          queryPtr,
          col.ptr,
          txnPtr,
          limit,
          countPtr,
        );
        await stream.first;
        return countPtr.value;
      } finally {
        malloc.free(countPtr);
      }
    });
  }

  @override
  bool deleteFirstSync() => deleteSyncInternal(1) == 1;

  @override
  int deleteAllSync() => deleteSyncInternal(maxLimit);

  int deleteSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = malloc<Uint32>();
      try {
        nCall(IC.isar_q_delete(
          queryPtr,
          col.ptr,
          txnPtr,
          limit,
          countPtr,
        ));
        return countPtr.value;
      } finally {
        malloc.free(countPtr);
      }
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
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback,
      {bool primitiveNull = true}) {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = malloc<Pointer<Uint8>>();
      final lengthPtr = malloc<Uint32>();
      final idNamePtr = col.idName.toNativeUtf8();
      IC.isar_q_export_json(queryPtr, col.ptr, txnPtr, idNamePtr.cast(),
          primitiveNull, bytesPtrPtr, lengthPtr);

      try {
        await stream.first;
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        malloc.free(bytesPtrPtr);
        malloc.free(lengthPtr);
        malloc.free(idNamePtr);
      }
    });
  }

  @override
  Future<R?> aggregate<R>(AggregationOp op) async {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultPtrPtr = malloc<Pointer>();

      IC.isar_q_aggregate(
          col.ptr, queryPtr, txnPtr, op.index, propertyId ?? 0, resultPtrPtr);

      try {
        await stream.first;
        return _convertAggregatedResult<R>(resultPtrPtr.value, op);
      } finally {
        malloc.free(resultPtrPtr);
      }
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultPtrPtr = malloc<Pointer>();

      try {
        nCall(IC.isar_q_aggregate(col.ptr, queryPtr, txnPtr, op.index,
            propertyId ?? 0, resultPtrPtr));
        return _convertAggregatedResult(resultPtrPtr.value, op);
      } finally {
        malloc.free(resultPtrPtr);
      }
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
