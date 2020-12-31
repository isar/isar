part of isar_native;

class NativeQuery<T extends IsarObjectMixin> extends Query<T> {
  final IsarCollectionImpl<T> col;
  final Pointer<NativeType> queryPtr;

  NativeQuery(this.col, this.queryPtr);

  @override
  Future<List<T>> findAll() {
    // TODO: implement findAll
    throw UnimplementedError();
  }

  @override
  List<T> findAllSync() {
    return col.isar.getTxnSync(false, (txnPtr) {
      final resultsPtr = allocate<RawObjectSet>();
      nativeCall(IsarCore.isar_q_find_all(queryPtr, txnPtr, resultsPtr));
      final objects = col.deserializeObjects(resultsPtr.ref);
      return objects;
    });
  }

  @override
  Future<int> count() {
    // TODO: implement count
    throw UnimplementedError();
  }

  @override
  int countSync() {
    // TODO: implement countSync
    throw UnimplementedError();
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
