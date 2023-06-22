part of isar;

class _IsarImpl extends Isar {
  _IsarImpl._(
    this.instanceId,
    this.engine,
    Pointer<CIsarInstance> ptr,
    this.converters,
  ) : _ptr = ptr {
    for (var i = 0; i < converters.length; i++) {
      final converter = converters[i];
      collections[converter.type] = converters[i].withType(
        <ID, OBJ>(converter) {
          return _IsarCollectionImpl<ID, OBJ>(this, i, converter);
        },
      );
    }

    _instances[instanceId] = this;
  }

  static final _instances = <int, _IsarImpl>{};

  final int instanceId;
  final StorageEngine engine;
  final List<IsarObjectConverter<dynamic, dynamic>> converters;
  final collections = <Type, _IsarCollectionImpl<dynamic, dynamic>>{};

  Pointer<CIsarInstance>? _ptr;
  Pointer<CIsarTxn>? _txnPtr;
  bool _txnWrite = false;

  factory _IsarImpl.open({
    required List<IsarCollectionSchema> schemas,
    required String directory,
    required StorageEngine engine,
    required String name,
    required int maxSizeMiB,
    required CompactCondition? compactOnLaunch,
  }) {
    final embeddedSchemas = <IsarSchema>{};
    for (final schema in schemas) {
      for (final schema in schema.embeddedSchemas) {
        embeddedSchemas.add(schema);
      }
    }
    final schemaJson =
        '[${[...schemas, ...embeddedSchemas].map((e) => e.schema).join(',')}]';

    final instanceId = Isar.fastHash(name);
    final instance = _IsarImpl._instances[instanceId];
    if (instance != null) {
      return instance;
    }

    final namePtr = IsarCore.toNativeString(name);
    final directoryPtr = IsarCore.toNativeString(directory);
    final schemaPtr = IsarCore.toNativeString(schemaJson);

    final isarPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarInstance>>();
    isar_open_instance(
      isarPtrPtr,
      instanceId,
      namePtr,
      directoryPtr,
      engine.cEngine,
      schemaPtr,
      maxSizeMiB,
      compactOnLaunch != null ? compactOnLaunch.minFileSize ?? 0 : -1,
      compactOnLaunch != null ? compactOnLaunch.minBytes ?? 0 : -1,
      compactOnLaunch != null ? compactOnLaunch.minRatio ?? 0 : double.nan,
    ).checkNoError();

    final converters = schemas.map((e) => e.converter).toList();
    return _IsarImpl._(instanceId, engine, isarPtrPtr.value, converters);
  }

  factory _IsarImpl.get({
    required int instanceId,
    required List<IsarObjectConverter<dynamic, dynamic>> converters,
    required StorageEngine engine,
  }) {
    final ptr = isar_get_instance(instanceId, engine.cEngine);
    if (ptr.isNull) {
      throw IsarNotReadyError('Instance has not been opened yet. Make sure to '
          'call Isar.open() before using Isar.get().');
    }

    return _IsarImpl._(instanceId, engine, ptr, converters);
  }

  factory _IsarImpl.getByName({
    required String name,
    required List<IsarCollectionSchema> schemas,
    required StorageEngine engine,
  }) {
    final instanceId = Isar.fastHash(name);
    final instance = _IsarImpl._instances[instanceId];
    if (instance != null) {
      return instance;
    }

    final converters = schemas.map((e) => e.converter).toList();
    return _IsarImpl.get(
      instanceId: instanceId,
      converters: converters,
      engine: engine,
    );
  }

  static _IsarImpl instance(int instanceId) {
    final instance = _instances[instanceId];
    if (instance == null) {
      throw IsarNotReadyError(
        'Isar instance has not been opened yet in this isolate. Call '
        'Isar.get() or Isar.open() before trying to access Isar for the first '
        'time in a new isolate.',
      );
    }
    return instance;
  }

  @pragma('vm:prefer-inline')
  Pointer<CIsarInstance> getPtr() {
    final ptr = _ptr;
    if (ptr == null) {
      throw IsarNotReadyError('Isar instance has already been closed.');
    } else {
      return ptr;
    }
  }

  @override
  late final String name = () {
    final length = isar_get_name(getPtr(), IsarCore.stringPtrPtr);
    return utf8.decode(IsarCore.stringPtr.asTypedList(length));
  }();

  @override
  late final String directory = () {
    final length = isar_get_dir(getPtr(), IsarCore.stringPtrPtr);
    return utf8.decode(IsarCore.stringPtr.asTypedList(length));
  }();

  @pragma('vm:prefer-inline')
  T getTxn<T>(
    T Function(
      Pointer<CIsarInstance> isarPtr,
      Pointer<CIsarTxn> txnPtr,
    ) callback,
  ) {
    final txnPtr = _txnPtr;
    if (txnPtr != null) {
      return callback(_ptr!, txnPtr);
    } else {
      return _txn(write: false, (isar) => callback(_ptr!, _txnPtr!));
    }
  }

  @pragma('vm:prefer-inline')
  T getWriteTxn<T>(
    (T, Pointer<CIsarTxn>?) Function(
      Pointer<CIsarInstance> isarPtr,
      Pointer<CIsarTxn> txnPtr,
    ) callback, {
    bool consume = false,
  }) {
    final txnPtr = _txnPtr;
    if (txnPtr != null) {
      if (_txnWrite) {
        if (consume) {
          _txnPtr = null;
        }
        final (result, returnedPtr) = callback(_ptr!, txnPtr);
        _txnPtr = returnedPtr;
        return result;
      }
    }
    throw WriteTxnRequiredError();
  }

  T _txn<T>(T Function(Isar isar) callback, {required bool write}) {
    if (_txnPtr != null) {
      throw UnsupportedError('Nested transactions are not supported');
    }

    final ptr = getPtr();
    final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
    isar_txn_begin(ptr, txnPtrPtr, write).checkNoError();
    try {
      _txnPtr = txnPtrPtr.value;
      _txnWrite = write;
      final result = callback(this);
      isar_txn_commit(ptr, _txnPtr!).checkNoError();
      return result;
    } catch (_) {
      final txnPtr = _txnPtr;
      if (txnPtr != null) {
        isar_txn_abort(ptr, txnPtr);
      }
      rethrow;
    } finally {
      _txnPtr = null;
    }
  }

  @override
  bool get isOpen => _ptr != null;

  @override
  IsarCollection<ID, OBJ> collection<ID, OBJ>() {
    final collection = collections[OBJ];
    if (collection is _IsarCollectionImpl<ID, OBJ>) {
      return collection;
    } else {
      throw ArgumentError('Collection for type $OBJ not found');
    }
  }

  @override
  T txn<T>(T Function(Isar isar) callback) {
    return _txn(callback, write: false);
  }

  @override
  T writeTxn<T>(T Function(Isar isar) callback) {
    return _txn(callback, write: true);
  }

  @override
  Future<T> txnAsync<T>(T Function(Isar isar) callback) {
    final instanceId = this.instanceId;
    final engine = this.engine;
    final converters = this.converters;
    return Isolate.run(
      () => _isarAsync(instanceId, engine, converters, false, callback),
    );
  }

  @override
  Future<T> writeTxnAsync<T>(T Function(Isar isar) callback) async {
    final instanceId = this.instanceId;
    final engine = this.engine;
    final converters = this.converters;
    return Isolate.run(
      () => _isarAsync(instanceId, engine, converters, true, callback),
    );
  }

  @override
  int getSize({bool includeIndexes = false}) {
    var size = 0;
    for (final collection in collections.values) {
      size += collection.getSize(includeIndexes: includeIndexes);
    }
    return size;
  }

  @override
  void copyToFile(String path) {
    final string = IsarCore.toNativeString(path);
    isar_copy(getPtr(), string).checkNoError();
  }

  @override
  void clear() {
    for (final collection in collections.values) {
      collection.clear();
    }
  }

  @override
  bool close({bool deleteFromDisk = false}) {
    final closed = isar_close(getPtr(), deleteFromDisk);
    _ptr = null;
    _instances.remove(instanceId);
    return closed;
  }
}

T _isarAsync<T>(
  int instanceId,
  StorageEngine engine,
  List<IsarObjectConverter<dynamic, dynamic>> converters,
  bool write,
  T Function(Isar isar) callback,
) {
  final isar = _IsarImpl.get(
    instanceId: instanceId,
    converters: converters,
    engine: engine,
  );
  try {
    if (write) {
      return isar.writeTxn(callback);
    } else {
      return isar.txn(callback);
    }
  } finally {
    isar.close();
    IsarCore.free();
  }
}

extension on StorageEngine {
  int get cEngine => switch (this) {
        StorageEngine.isar => CStorageEngine.Isar,
        StorageEngine.sqlite => CStorageEngine.SQLite,
        StorageEngine.sqlcipher => CStorageEngine.SQLCipher,
      };
}
