part of isar_native;

class NativeQuery<OBJECT> extends Query<OBJECT> {
  final IsarCollectionImpl<dynamic, OBJECT> col;
  final Pointer<NativeType> queryPtr;

  NativeQuery(this.col, this.queryPtr);

  @override
  Future<List<OBJECT>> findAll() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = calloc<RawObjectSet>();
      try {
        IC.isar_q_find_all_async(queryPtr, txnPtr, resultsPtr);
        await stream.first;
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        IC.isar_free_raw_obj_list(resultsPtr);
        calloc.free(resultsPtr);
      }
    });
  }

  @override
  List<OBJECT> findAllSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = calloc<RawObjectSet>();
      try {
        nCall(IC.isar_q_find_all(queryPtr, txnPtr, resultsPtr));
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        calloc.free(resultsPtr);
      }
    });
  }

  @override
  Future<int> count() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = calloc<Int64>();
      try {
        IC.isar_q_count_async(queryPtr, txnPtr, countPtr);
        await stream.first;
        return countPtr.value;
      } finally {
        calloc.free(countPtr);
      }
    });
  }

  @override
  int countSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = calloc<Int64>();
      try {
        nCall(IC.isar_q_count(queryPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        calloc.free(countPtr);
      }
    });
  }

  @override
  Future<bool> deleteFirst() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final deletedPtr = calloc<Uint8>();
      try {
        IC.isar_q_delete_first_async(
            queryPtr, col.collectionPtr, txnPtr, deletedPtr);
        await stream.first;
        return deletedPtr.value != 0;
      } finally {
        calloc.free(deletedPtr);
      }
    });
  }

  @override
  bool deleteFirstSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final deletedPtr = calloc<Uint8>();
      try {
        nCall(IC.isar_q_delete_first(
            queryPtr, col.collectionPtr, txnPtr, deletedPtr));
        return deletedPtr.value != 0;
      } finally {
        calloc.free(deletedPtr);
      }
    });
  }

  @override
  Future<int> deleteAll() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final countPtr = calloc<Int64>();
      try {
        IC.isar_q_delete_all_async(
            queryPtr, col.collectionPtr, txnPtr, countPtr);
        await stream.first;
        return countPtr.value;
      } finally {
        calloc.free(countPtr);
      }
    });
  }

  @override
  int deleteAllSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final countPtr = calloc<Int64>();
      try {
        nCall(IC.isar_q_delete_all(
            queryPtr, col.collectionPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        calloc.free(countPtr);
      }
    });
  }

  @override
  Stream<void> watchChanges() {
    throw UnimplementedError();
  }

  @override
  Stream<List<OBJECT>> watch() {
    throw UnimplementedError();
  }
}
