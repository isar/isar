part of isar_native;

class NativeQuery<OBJ> extends Query<OBJ> {
  static const MAX_LIMIT = 4294967295;

  final IsarCollectionImpl<OBJ> col;
  final Pointer<NativeType> queryPtr;

  NativeQuery(this.col, this.queryPtr);

  @override
  Future<OBJ?> findFirst() => findInternal(MAX_LIMIT).then((value) => value[0]);

  @override
  Future<List<OBJ>> findAll() => findInternal(MAX_LIMIT);

  Future<List<OBJ>> findInternal(int limit) {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = allocate<RawObjectSet>();
      try {
        IC.isar_q_find_async(queryPtr, txnPtr, resultsPtr, limit);
        await stream.first;
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
        free(resultsPtr);
      }
    });
  }

  @override
  OBJ? findFirstSync() => findSyncInternal(1)[0];

  @override
  List<OBJ> findAllSync() => findSyncInternal(MAX_LIMIT);

  List<OBJ> findSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = allocate<RawObjectSet>();
      try {
        nCall(IC.isar_q_find(queryPtr, txnPtr, resultsPtr, limit));
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        free(resultsPtr);
      }
    });
  }

  @override
  Future<int> count() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = allocate<Uint32>();
      try {
        IC.isar_q_count_async(queryPtr, txnPtr, countPtr);
        await stream.first;
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  int countSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = allocate<Uint32>();
      try {
        nCall(IC.isar_q_count(queryPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() => deleteInternal(1).then((count) => count == 1);

  @override
  Future<int> deleteAll() => deleteInternal(MAX_LIMIT);

  Future<int> deleteInternal(int limit) {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = allocate<Uint32>();
      try {
        IC.isar_q_delete_async(
          queryPtr,
          col.ptr,
          txnPtr,
          limit,
          countPtr,
        );
        await stream.first;
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  bool deleteFirstSync() => deleteSyncInternal(1) == 1;

  @override
  int deleteAllSync() => deleteSyncInternal(MAX_LIMIT);

  int deleteSyncInternal(int limit) {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = allocate<Uint32>();
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
        free(countPtr);
      }
    });
  }

  @override
  Stream<List<OBJ>?> watch({bool lazy = true, bool initialReturn = false}) {
    final port = ReceivePort();
    final handle = IC.isar_watch_query(
        col.isar.isarPtr, col.ptr, queryPtr, port.sendPort.nativePort);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    if (initialReturn) {
      controller.add(findAll());
    }

    controller.addStream(port);

    if (lazy) {
      return controller.stream.map((event) => null);
    } else {
      return controller.stream.asyncMap((event) => findAll());
    }
  }
}
