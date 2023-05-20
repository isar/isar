part of isar;

T _isarAsync<T>(
  int instanceId,
  List<ObjectConverter<dynamic, dynamic>> converters,
  bool write,
  T Function(Isar isar) callback,
) {
  final isar = _IsarImpl.get(instanceId: instanceId, converters: converters);
  try {
    if (write) {
      return isar.writeTxn(callback);
    } else {
      return isar.txn(callback);
    }
  } finally {
    isar.close();
    IsarCore._free();
  }
}

extension IsarAsync on Isar {
  Future<T> txnAsync<T>(T Function(Isar isar) callback) {
    final isar = this as _IsarImpl;
    final instanceId = isar.instanceId;
    final converters = isar.converters;
    return Isolate.run(
      () => _isarAsync(instanceId, converters, false, callback),
    );
  }

  Future<T> writeTxnAsync<T>(T Function(Isar isar) callback) async {
    final isar = this as _IsarImpl;
    final instanceId = isar.instanceId;
    final converters = isar.converters;
    return Isolate.run(
      () => _isarAsync(instanceId, converters, true, callback),
    );
  }

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

extension QueryAsync<T> on Query<T> {
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
