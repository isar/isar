part of isar_native;

typedef QueryDeserialize<T> = List<T> Function(RawObjectSet);

class NativeQuery<T> extends Query<T> {
  static const MAX_LIMIT = 4294967295;

  final IsarImpl isar;
  final Pointer<NativeType> colPtr;
  final Pointer<NativeType> queryPtr;
  final QueryDeserialize<T> deserialize;
  final int? propertyIndex;

  NativeQuery(this.isar, this.colPtr, this.queryPtr, this.deserialize,
      this.propertyIndex);

  @override
  Future<T?> findFirst() {
    return findInternal(MAX_LIMIT).then((result) {
      if (result.isNotEmpty) {
        return result[0];
      }
    });
  }

  @override
  Future<List<T>> findAll() => findInternal(MAX_LIMIT);

  Future<List<T>> findInternal(int limit) {
    return isar.getTxn(false, (txnPtr, stream) async {
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
  List<T> findAllSync() => findSyncInternal(MAX_LIMIT);

  List<T> findSyncInternal(int limit) {
    return isar.getTxnSync(false, (txnPtr) {
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
  Future<int> deleteAll() => deleteInternal(MAX_LIMIT);

  Future<int> deleteInternal(int limit) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = malloc<Uint32>();
      try {
        IC.isar_q_delete(
          queryPtr,
          colPtr,
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
  int deleteAllSync() => deleteSyncInternal(MAX_LIMIT);

  int deleteSyncInternal(int limit) {
    return isar.getTxnSync(false, (txnPtr) {
      final countPtr = malloc<Uint32>();
      try {
        nCall(IC.isar_q_delete(
          queryPtr,
          colPtr,
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
        isar.isarPtr, colPtr, queryPtr, port.sendPort.nativePort);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    if (initialReturn) {
      controller.add(true);
    }

    controller.addStream(port);
    return controller.stream;
  }
}

Future<T?> aggregateQuery<T>(Query query, AggregationOp op) async {
  query as NativeQuery;
  return query.isar.getTxn(false, (txnPtr, stream) async {
    final resultPtrPtr = malloc<Pointer>();

    IC.isar_q_aggregate(query.colPtr, query.queryPtr, txnPtr, op.index,
        query.propertyIndex ?? 0, resultPtrPtr);

    try {
      await stream.first;
      return _convertAggregatedResult<T>(resultPtrPtr.value, op);
    } finally {
      malloc.free(resultPtrPtr);
    }
  });
}

T? aggregateQuerySync<T>(Query query, AggregationOp op) {
  query as NativeQuery;
  return query.isar.getTxnSync(false, (txnPtr) {
    final resultPtrPtr = malloc<Pointer>();

    try {
      nCall(IC.isar_q_aggregate(query.colPtr, query.queryPtr, txnPtr, op.index,
          query.propertyIndex ?? 0, resultPtrPtr));
      return _convertAggregatedResult(resultPtrPtr.value, op);
    } finally {
      malloc.free(resultPtrPtr);
    }
  });
}

T? _convertAggregatedResult<T>(Pointer resultPtr, AggregationOp op) {
  final nullable = op == AggregationOp.Min || op == AggregationOp.Max;
  if (T == int || T == DateTime) {
    final value = IC.isar_q_aggregate_long_result(resultPtr);
    if (nullable && value == nullLong) {
      return null;
    }
    if (T == int) {
      return value as T;
    } else {
      return DateTime.fromMicrosecondsSinceEpoch(value, isUtc: true).toLocal()
          as T;
    }
  } else {
    final value = IC.isar_q_aggregate_double_result(resultPtr);
    if (nullable && value.isNaN) {
      return null;
    } else {
      return value as T;
    }
  }
}
