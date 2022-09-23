// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/txn.dart';

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
      final resultsPtr = txn.alloc<CObjectSet>();
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
    return col.isar.getTxnSync(false, (Txn txn) {
      final resultsPtr = txn.getCObjectsSet();
      try {
        nCall(IC.isar_q_find(queryPtr, txn.ptr, resultsPtr, limit));
        return deserialize(resultsPtr.ref).cast();
      } finally {
        IC.isar_free_c_object_set(resultsPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() =>
      deleteInternal(1).then((int count) => count == 1);

  @override
  Future<int> deleteAll() => deleteInternal(maxLimit);

  Future<int> deleteInternal(int limit) {
    return col.isar.getTxn(false, (Txn txn) async {
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
    return col.isar.getTxnSync(false, (Txn txn) {
      final countPtr = txn.alloc<Uint32>();
      nCall(IC.isar_q_delete(queryPtr, col.ptr, txn.ptr, limit, countPtr));
      return countPtr.value;
    });
  }

  @override
  Stream<List<T>> watch({bool fireImmediately = false}) {
    return watchLazy(fireImmediately: fireImmediately)
        .asyncMap((event) => findAll());
  }

  @override
  Stream<void> watchLazy({bool fireImmediately = false}) {
    final port = ReceivePort();
    final handle = IC.isar_watch_query(
      col.isar.ptr,
      col.ptr,
      queryPtr,
      port.sendPort.nativePort,
    );

    final controller = StreamController<void>(
      onCancel: () {
        IC.isar_stop_watching(handle);
        port.close();
      },
    );

    if (fireImmediately) {
      controller.add(null);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  Future<R> exportJsonRaw<R>(R Function(Uint8List) callback) {
    return col.isar.getTxn(false, (Txn txn) async {
      final bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final lengthPtr = txn.alloc<Uint32>();
      final idNamePtr = col.schema.idName.toCString(txn.alloc);

      nCall(
        IC.isar_q_export_json(
          queryPtr,
          col.ptr,
          txn.ptr,
          idNamePtr,
          bytesPtrPtr,
          lengthPtr,
        ),
      );

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
    return col.isar.getTxnSync(false, (Txn txn) {
      final bytesPtrPtr = txn.alloc<Pointer<Uint8>>();
      final lengthPtr = txn.alloc<Uint32>();
      final idNamePtr = col.schema.idName.toCString(txn.alloc);

      try {
        nCall(
          IC.isar_q_export_json(
            queryPtr,
            col.ptr,
            txn.ptr,
            idNamePtr,
            bytesPtrPtr,
            lengthPtr,
          ),
        );
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
      }
    });
  }

  @override
  Future<R?> aggregate<R>(AggregationOp op) async {
    return col.isar.getTxn(false, (Txn txn) async {
      final resultPtrPtr = txn.alloc<Pointer<CAggregationResult>>();

      IC.isar_q_aggregate(
        col.ptr,
        queryPtr,
        txn.ptr,
        op.index,
        propertyId ?? 0,
        resultPtrPtr,
      );
      await txn.wait();

      return _convertAggregatedResult<R>(resultPtrPtr.value, op);
    });
  }

  @override
  R? aggregateSync<R>(AggregationOp op) {
    return col.isar.getTxnSync(false, (Txn txn) {
      final resultPtrPtr = txn.alloc<Pointer<CAggregationResult>>();

      nCall(
        IC.isar_q_aggregate(
          col.ptr,
          queryPtr,
          txn.ptr,
          op.index,
          propertyId ?? 0,
          resultPtrPtr,
        ),
      );
      return _convertAggregatedResult(resultPtrPtr.value, op);
    });
  }

  R? _convertAggregatedResult<R>(
    Pointer<CAggregationResult> resultPtr,
    AggregationOp op,
  ) {
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
