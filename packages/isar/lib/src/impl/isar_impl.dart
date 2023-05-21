part of isar;

class _IsarImpl extends Isar {
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

  static _IsarImpl get({
    required int instanceId,
    required List<ObjectConverter<dynamic, dynamic>> converters,
  }) {
    final instance = _instances[instanceId];
    if (instance != null) {
      return instance;
    }

    final ptr = isar_get_instance(instanceId);
    if (ptr.isNull) {
      throw IsarNotReadyError('Instance has not been opened yet. Make sure to '
          'call Isar.open() before using Isar.get().');
    }

    return _IsarImpl._(instanceId, ptr, converters);
  }

  static _IsarImpl open({
    required List<CollectionSchema> schemas,
    required String directory,
    required String name,
    required int maxSizeMiB,
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
  int getSize({bool includeIndexes = false}) {
    var size = 0;
    for (final collection in collections.values) {
      size += collection.getSize(includeIndexes: includeIndexes);
    }
    return size;
  }

  @override
  void importJsonBytes(Uint8List jsonBytes) {
    // TODO: implement importJsonBytes
  }

  @override
  void importJsonFile(String path) {
    // TODO: implement importJsonFile
  }

  @override
  R exportJsonBytes<R>(R Function(Uint8List jsonBytes) callback) {
    // TODO: implement exportJsonBytes
    throw UnimplementedError();
  }

  @override
  void exportJsonFile(String path) {
    // TODO: implement exportJsonFile
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
    return closed;
  }
}
