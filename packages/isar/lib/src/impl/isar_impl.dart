part of isar;

class _IsarImpl implements Isar {
  _IsarImpl._(this.instanceId, Pointer<CIsarInstance> ptr, this.converters)
      : _ptr = ptr {
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
  final List<ObjectConverter<dynamic, dynamic>> converters;
  final collections = <Type, _IsarCollectionImpl<dynamic, dynamic>>{};

  Pointer<CIsarInstance>? _ptr;
  Pointer<CIsarTxn>? _txnPtr;
  bool _txnWrite = false;

  factory _IsarImpl.get({
    required int instanceId,
    required List<ObjectConverter<dynamic, dynamic>> converters,
  }) {
    final instance = _instances[instanceId];
    if (instance != null) {
      return instance;
    }

    final ptr = isar_get_instance(instanceId);
    if (ptr.isNull) {
      throw IsarError('Instance has not been opened yet. Make sure to '
          'call Isar.open() before calling Isar.get().');
    }

    return _IsarImpl._(instanceId, ptr, converters);
  }

  factory _IsarImpl.open({
    required List<CollectionSchema> schemas,
    required String directory,
    required String name,
    required int maxSizeMiB,
    required bool relaxedDurability,
    required CompactCondition? compactOnLaunch,
    required bool inspector,
  }) {
    final allSchemas = <Schema>{};
    for (final schema in schemas) {
      allSchemas.add(schema);
      for (final schema in schema.embeddedSchemas) {
        allSchemas.add(schema);
      }
    }
    final schemaJson = '[${allSchemas.map((e) => e.schema).join(',')}]';

    final instanceId = Isar.fastHash(name);
    final namePtr = IsarCore.toNativeString(name);
    final directoryPtr = IsarCore.toNativeString(directory);
    final schemaPtr = IsarCore.toNativeString(schemaJson);

    final isarPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarInstance>>();
    isar_open_instance(
      isarPtrPtr,
      instanceId,
      namePtr,
      directoryPtr,
      schemaPtr,
      maxSizeMiB,
      relaxedDurability,
      compactOnLaunch?.minFileSize ?? -1,
      compactOnLaunch?.minBytes ?? -1,
      compactOnLaunch?.minRatio ?? double.nan,
    ).checkNoError();

    final converters = schemas.map((e) => e.converter).toList();
    return _IsarImpl._(instanceId, isarPtrPtr.value, converters);
  }

  static _IsarImpl getInstance(int instanceId) {
    final instance = _instances[instanceId];
    if (instance == null) {
      throw IsarError('Instance has not been opened yet in this isolate.');
    }
    return instance;
  }

  @pragma('vm:prefer-inline')
  Pointer<CIsarInstance> getPtr() {
    final ptr = _ptr;
    if (ptr == null) {
      throw IsarError('Isar instance has already been closed');
    } else {
      return ptr;
    }
  }

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
      } else {
        throw 'Write txn required';
      }
    } else {
      throw 'Explicit write transaction required';
    }
  }

  T _txn<T>(T Function(Isar isar) callback, {required bool write}) {
    if (_txnPtr != null) {
      throw 'Nested transactions are not supported';
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
      throw IsarError('Collection for type $OBJ not found');
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
  void clear() {
    for (final collection in collections.values) {
      collection.clear();
    }
  }

  @override
  int getSize({bool includeIndexes = false}) {
    return 0;
  }

  @override
  void copyToFile(String targetFilePath) {}

  @override
  bool close({bool deleteFromDisk = false}) {
    final closed = isar_close(_ptr!, deleteFromDisk);
    _ptr = null;
    return closed;
  }
}
