part of isar;

extension CollectionAsync<ID, OBJ> on IsarCollection<ID, OBJ> {
  Future<OBJ?> getAsync(ID id) {
    return isar.txnAsync((isar) => isar.collection<ID, OBJ>().get(id));
  }

  Future<List<OBJ?>> getAllAsync(List<ID> ids) {
    return isar.txnAsync((isar) => isar.collection<ID, OBJ>().getAll(ids));
  }
}

extension QueryAsync<T> on IsarQuery<T> {
  Future<T?> findFirstAsync() => isar.txnAsync((isar) => findFirst());

  Future<List<T>> findAllAsync({int? offset, int? limit}) =>
      isar.txnAsync((isar) => findAll(offset: offset, limit: limit));

  Future<int> countAsync() => isar.txnAsync((isar) => count());

  Future<bool> isEmptyAsync() => isar.txnAsync((isar) => isEmpty());

  Future<bool> isNotEmptyAsync() => isar.txnAsync((isar) => isNotEmpty());

  @protected
  Future<R?> aggregateAsync<R>(Aggregation op) =>
      isar.txnAsync((isar) => aggregate(op));
}
