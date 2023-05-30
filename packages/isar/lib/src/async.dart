part of isar;

extension IsarAsync on Isar {
  Future<Map<String, dynamic>> exportJsonAsync() {
    return txnAsync((isar) {
      return isar.exportJsonBytes((jsonBytes) {
        return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      });
    });
  }

  Future<void> exportJsonFileAsync(String path) {
    return txnAsync((isar) => isar.exportJsonFile(path));
  }
}

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

  Future<Map<String, dynamic>> exportJsonAsync({int? offset, int? limit}) {
    return isar.txnAsync((isar) {
      return exportJsonBytes(offset: offset, limit: limit, (jsonBytes) {
        return jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;
      });
    });
  }

  Future<void> exportJsonFileAsync(String path) {
    return isar.txnAsync((isar) => exportJsonFile(path));
  }

  @protected
  Future<R?> aggregateAsync<R>(Aggregation op) =>
      isar.txnAsync((isar) => aggregate(op));
}
