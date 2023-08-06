part of isar;

class _IsarImpl extends Isar {
  _IsarImpl._(
    this.instanceId,
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
  final List<IsarObjectConverter<dynamic, dynamic>> converters;
  final collections = <Type, _IsarCollectionImpl<dynamic, dynamic>>{};

  Pointer<CIsarInstance>? _ptr;
  Pointer<CIsarTxn>? _txnPtr;
  bool _txnWrite = false;

  // ignore: sort_constructors_first
  factory _IsarImpl.open({
    required List<IsarCollectionSchema> schemas,
    required String name,
    required IsarEngine engine,
    required String directory,
    required int? maxSizeMiB,
    required String? encryptionKey,
    required CompactCondition? compactOnLaunch,
    String? library,
  }) {
    IsarCore._initialize(library: library);

    if (engine == IsarEngine.isar) {
      if (encryptionKey != null) {
        throw ArgumentError('Isar engine does not support encryption.');
      }
      maxSizeMiB ??= Isar.defaultMaxSizeMiB;
    } else {
      if (compactOnLaunch != null) {
        throw ArgumentError('SQLite engine does not support compaction.');
      }
      maxSizeMiB ??= 0;
    }

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

    final namePtr = IsarCore._toNativeString(name);
    final directoryPtr = IsarCore._toNativeString(directory);
    final schemaPtr = IsarCore._toNativeString(schemaJson);
    final encryptionKeyPtr = encryptionKey != null
        ? IsarCore._toNativeString(encryptionKey)
        : nullptr;

    final isarPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarInstance>>();
    IsarCore.b
        .isar_open_instance(
          isarPtrPtr,
          instanceId,
          namePtr,
          directoryPtr,
          engine == IsarEngine.sqlite,
          schemaPtr,
          maxSizeMiB,
          encryptionKeyPtr,
          compactOnLaunch != null ? compactOnLaunch.minFileSize ?? 0 : -1,
          compactOnLaunch != null ? compactOnLaunch.minBytes ?? 0 : -1,
          compactOnLaunch != null ? compactOnLaunch.minRatio ?? 0 : double.nan,
        )
        .checkNoError();

    final converters = schemas.map((e) => e.converter).toList();
    return _IsarImpl._(instanceId, isarPtrPtr.ptrValue, converters);
  }

  // ignore: sort_constructors_first
  factory _IsarImpl.get({
    required int instanceId,
    required List<IsarObjectConverter<dynamic, dynamic>> converters,
    String? library,
  }) {
    IsarCore._initialize(library: library);
    var ptr = IsarCore.b.isar_get_instance(instanceId, false);
    if (ptr.isNull) {
      ptr = IsarCore.b.isar_get_instance(instanceId, true);
    }
    if (ptr.isNull) {
      throw IsarNotReadyError('Instance has not been opened yet. Make sure to '
          'call Isar.open() before using Isar.get().');
    }

    return _IsarImpl._(instanceId, ptr, converters);
  }

  // ignore: sort_constructors_first
  factory _IsarImpl.getByName({
    required String name,
    required List<IsarCollectionSchema> schemas,
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
    );
  }

  static Future<Isar> openAsync({
    required List<IsarCollectionSchema> schemas,
    required String directory,
    String name = Isar.defaultName,
    IsarEngine engine = IsarEngine.isar,
    int? maxSizeMiB = Isar.defaultMaxSizeMiB,
    String? encryptionKey,
    CompactCondition? compactOnLaunch,
  }) async {
    final library = IsarCore._library;

    final receivePort = ReceivePort();
    final sendPort = receivePort.sendPort;
    final isolate = scheduleIsolate(
      () async {
        try {
          final isar = _IsarImpl.open(
            schemas: schemas,
            directory: directory,
            name: name,
            engine: engine,
            maxSizeMiB: maxSizeMiB,
            encryptionKey: encryptionKey,
            compactOnLaunch: compactOnLaunch,
            library: library,
          );

          final receivePort = ReceivePort();
          sendPort.send(receivePort.sendPort);
          await receivePort.first;
          isar.close();
        } catch (e) {
          sendPort.send(e);
        }
      },
      debugName: 'Isar open async',
    );

    final response = await receivePort.first;
    if (response is SendPort) {
      final isar = Isar.get(schemas: schemas, name: name);
      response.send(null);
      await isolate;
      return isar;
    } else {
      throw response as Object;
    }
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

  @tryInline
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
    final length = IsarCore.b.isar_get_name(getPtr(), IsarCore.stringPtrPtr);
    return utf8.decode(IsarCore.stringPtr.asU8List(length));
  }();

  @override
  late final String directory = () {
    final length = IsarCore.b.isar_get_dir(getPtr(), IsarCore.stringPtrPtr);
    return utf8.decode(IsarCore.stringPtr.asU8List(length));
  }();

  @tryInline
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

  @tryInline
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

  void _checkNotInTxn() {
    if (_txnPtr != null) {
      throw UnsupportedError('Nested transactions are not supported');
    }
  }

  T _txn<T>(T Function(Isar isar) callback, {required bool write}) {
    _checkNotInTxn();

    final ptr = getPtr();
    final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
    IsarCore.b.isar_txn_begin(ptr, txnPtrPtr, write).checkNoError();
    try {
      _txnPtr = txnPtrPtr.ptrValue;
      _txnWrite = write;
      final result = callback(this);
      IsarCore.b.isar_txn_commit(ptr, _txnPtr!).checkNoError();
      return result;
    } catch (_) {
      final txnPtr = _txnPtr;
      if (txnPtr != null) {
        IsarCore.b.isar_txn_abort(ptr, txnPtr);
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
  T read<T>(T Function(Isar isar) callback) {
    return _txn(callback, write: false);
  }

  @override
  T write<T>(T Function(Isar isar) callback) {
    return _txn(callback, write: true);
  }

  @override
  Future<T> readAsyncWith<T, P>(
    P param,
    T Function(Isar isar, P param) callback, {
    String? debugName,
  }) {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    _checkNotInTxn();

    final instanceId = this.instanceId;
    final library = IsarCore._library;
    final converters = this.converters;
    return scheduleIsolate(
      () => _isarAsync(
        instanceId,
        library,
        converters,
        false,
        param,
        callback,
      ),
      debugName: debugName ?? 'Isar async read',
    );
  }

  @override
  Future<T> writeAsyncWith<T, P>(
    P param,
    T Function(Isar isar, P param) callback, {
    String? debugName,
  }) async {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    _checkNotInTxn();

    final instanceId = this.instanceId;
    final library = IsarCore._library;
    final converters = this.converters.toList();
    return scheduleIsolate(
      () {
        return _isarAsync(
          instanceId,
          library,
          converters,
          true,
          param,
          callback,
        );
      },
      debugName: debugName ?? 'Isar async write',
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
    final string = IsarCore._toNativeString(path);
    IsarCore.b.isar_copy(getPtr(), string).checkNoError();
  }

  @override
  void clear() {
    for (final collection in collections.values) {
      collection.clear();
    }
  }

  @override
  bool close({bool deleteFromDisk = false}) {
    final closed = IsarCore.b.isar_close(getPtr(), deleteFromDisk);
    _ptr = null;
    _instances.remove(instanceId);
    return closed != 0;
  }

  @override
  void verify() {
    getTxn(
      (isarPtr, txnPtr) =>
          IsarCore.b.isar_verify(isarPtr, txnPtr).checkNoError(),
    );
  }
}

T _isarAsync<T, P>(
  int instanceId,
  String? library,
  List<IsarObjectConverter<dynamic, dynamic>> converters,
  bool write,
  P param,
  T Function(Isar isar, P param) callback,
) {
  final isar = _IsarImpl.get(
    instanceId: instanceId,
    converters: converters,
    library: library,
  );
  try {
    if (write) {
      return isar.write((isar) => callback(isar, param));
    } else {
      return isar.read((isar) => callback(isar, param));
    }
  } finally {
    isar.close();
    IsarCore._free();
  }
}
