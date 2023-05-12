part of isar;

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
}

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
  }
}
