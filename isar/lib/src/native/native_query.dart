part of isar_native;

class NativeQuery<OBJECT> extends Query<OBJECT> {
  final IsarCollectionImpl<dynamic, OBJECT> col;
  final Pointer<NativeType> queryPtr;

  NativeQuery(this.col, this.queryPtr);

  @override
  Future<List<OBJECT>> findAll() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = allocate<RawObjectSet>();
      try {
        IC.isar_q_find_all_async(queryPtr, txnPtr, resultsPtr);
        await stream.first;
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
        free(resultsPtr);
      }
    });
  }

  @override
  List<OBJECT> findAllSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = allocate<RawObjectSet>();
      try {
        nCall(IC.isar_q_find_all(queryPtr, txnPtr, resultsPtr));
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        free(resultsPtr);
      }
    });
  }

  @override
  Future<int> count() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = allocate<Int64>();
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
      final countPtr = allocate<Int64>();
      try {
        nCall(IC.isar_q_count(queryPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final deletedPtr = allocate<Uint8>();
      try {
        IC.isar_q_delete_first_async(
            queryPtr, col.collectionPtr, txnPtr, deletedPtr);
        await stream.first;
        return deletedPtr.value != 0;
      } finally {
        free(deletedPtr);
      }
    });
  }

  @override
  bool deleteFirstSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final deletedPtr = allocate<Uint8>();
      try {
        nCall(IC.isar_q_delete_first(
            queryPtr, col.collectionPtr, txnPtr, deletedPtr));
        return deletedPtr.value != 0;
      } finally {
        free(deletedPtr);
      }
    });
  }

  @override
  Future<int> deleteAll() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = allocate<Int64>();
      try {
        IC.isar_q_delete_all_async(
            queryPtr, col.collectionPtr, txnPtr, countPtr);
        await stream.first;
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  int deleteAllSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = allocate<Int64>();
      try {
        nCall(IC.isar_q_delete_all(
            queryPtr, col.collectionPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  Stream<List<OBJECT>?> watch({bool lazy = true}) {
    final port = ReceivePort();
    final handle = IC.isar_watch_query(col.isar.isarPtr, col.collectionPtr,
        queryPtr, port.sendPort.nativePort);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    controller.addStream(port);

    if (lazy) {
      return controller.stream.map((event) => null);
    } else {
      return controller.stream.asyncMap((event) => findAll());
    }
  }
}
