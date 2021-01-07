part of isar_native;

class NativeQuery<T extends IsarObject> extends Query<T> {
  final IsarCollectionImpl<T> col;
  final Pointer<NativeType> queryPtr;

  NativeQuery(this.col, this.queryPtr);

  @override
  Future<List<T>> findAll() {
    return col.isar.getTxn(false, (txnPtr, stream) async {
      final resultsPtr = allocate<RawObjectSet>();
      try {
        IC.isar_q_find_all_async(queryPtr, txnPtr, resultsPtr);
        await stream.first;
        return col.deserializeObjects(resultsPtr.ref);
      } finally {
        free(resultsPtr);
      }
    });
  }

  @override
  List<T> findAllSync() {
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
        //IC.isar_q_count_async(queryPtr, txnPtr, countPtr);
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
        //nCall(IC.isar_q_count(queryPtr, txnPtr, countPtr));
        return countPtr.value;
      } finally {
        free(countPtr);
      }
    });
  }

  @override
  Future<int> deleteAll() {
    // TODO: implement deleteAll
    throw UnimplementedError();
  }

  @override
  int deleteAllSync() {
    // TODO: implement deleteAllSync
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteFirst() {
    // TODO: implement deleteFirst
    throw UnimplementedError();
  }

  @override
  T deleteFirstSync() {
    // TODO: implement deleteFirstSync
    throw UnimplementedError();
  }
}
