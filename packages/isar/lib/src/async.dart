part of isar;

extension CollectionAsync<ID, OBJ> on IsarCollection<ID, OBJ> {
  Future<OBJ?> getAsync(ID id) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().get(id));
  }

  Future<List<OBJ?>> getAllAsync(List<ID> ids) {
    return isar.readAsync((isar) => isar.collection<ID, OBJ>().getAll(ids));
  }
}

extension QueryAsync<T> on IsarQuery<T> {
  Future<T?> findFirstAsync({int? offset}) =>
      isar.readAsync((isar) => findFirst(offset: offset));

  Future<List<T>> findAllAsync({int? offset, int? limit}) =>
      isar.readAsync((isar) => findAll(offset: offset, limit: limit));

  Future<int> countAsync() => isar.readAsync((isar) => count());

  Future<bool> isEmptyAsync() => isar.readAsync((isar) => isEmpty());

  Future<bool> isNotEmptyAsync() => isar.readAsync((isar) => isNotEmpty());

  @protected
  Future<R?> aggregateAsync<R>(Aggregation op) =>
      isar.readAsync((isar) => aggregate(op));
}
