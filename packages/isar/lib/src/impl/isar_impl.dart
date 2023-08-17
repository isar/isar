part of isar;

class _IsarImpl extends Isar {
  _IsarImpl._(
    this.instanceId,
    Pointer<CIsarInstance> ptr,
    this.generatedSchemas,
  ) : _ptr = ptr {
    for (final schema in generatedSchemas) {
      if (schema.isEmbedded) {
        continue;
      }

      collections[schema.converter.type] = schema.converter.withType(
        <ID, OBJ>(converter) {
          return _IsarCollectionImpl<ID, OBJ>(
            this,
            schema.schema,
            collections.length,
            converter,
          );
        },
      );
    }

    _instances[instanceId] = this;
  }

  static final _instances = <int, _IsarImpl>{};

  final int instanceId;
  final List<IsarGeneratedSchema> generatedSchemas;
  final collections = <Type, _IsarCollectionImpl<dynamic, dynamic>>{};

  Pointer<CIsarInstance>? _ptr;
  Pointer<CIsarTxn>? _txnPtr;
  bool _txnWrite = false;

  // ignore: sort_constructors_first
  factory _IsarImpl.open({
    required List<IsarGeneratedSchema> schemas,
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
        throw ArgumentError('Isar engine does not support encryption. Please '
            'set the engine to IsarEngine.sqlite.');
      }
      maxSizeMiB ??= Isar.defaultMaxSizeMiB;
    } else {
      if (compactOnLaunch != null) {
        throw ArgumentError('SQLite engine does not support compaction.');
      }
      maxSizeMiB ??= 0;
    }

    final allSchemas = <IsarGeneratedSchema>{
      ...schemas,
      ...schemas.expand((e) => e.embeddedSchemas ?? <IsarGeneratedSchema>[]),
    };
    final schemaJson =
        jsonEncode(allSchemas.map((e) => e.schema.toJson()).toList());

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

    return _IsarImpl._(instanceId, isarPtrPtr.ptrValue, allSchemas.toList());
  }

  // ignore: sort_constructors_first
  factory _IsarImpl.get({
    required int instanceId,
    required List<IsarGeneratedSchema> schemas,
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

    return _IsarImpl._(instanceId, ptr, schemas);
  }

  // ignore: sort_constructors_first
  factory _IsarImpl.getByName({
    required String name,
    required List<IsarGeneratedSchema> schemas,
  }) {
    final instanceId = Isar.fastHash(name);
    final instance = _IsarImpl._instances[instanceId];
    if (instance != null) {
      return instance;
    }

    return _IsarImpl.get(
      instanceId: instanceId,
      schemas: schemas,
    );
  }

  static Future<Isar> openAsync({
    required List<IsarGeneratedSchema> schemas,
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
    final isolate = runIsolate(
      'Isar open async',
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
    );

    final response = await receivePort.first;
    if (response is SendPort) {
      final isar = Isar.get(schemas: schemas, name: name);
      response.send(null);
      await isolate;
      return isar;
    } else {
      // ignore: only_throw_errors
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

  @override
  late final List<IsarSchema> schemas =
      generatedSchemas.map((e) => e.schema).toList();

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
  IsarCollection<ID, OBJ> collectionByIndex<ID, OBJ>(int index) {
    final collection = collections.values.elementAt(index);
    if (collection is _IsarCollectionImpl<ID, OBJ>) {
      return collection;
    } else {
      throw ArgumentError('Invalid type parameters for collection');
    }
  }

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
      return read((isar) => callback(_ptr!, _txnPtr!));
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

  @override
  T read<T>(T Function(Isar isar) callback) {
    _checkNotInTxn();

    final ptr = getPtr();
    final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
    IsarCore.b.isar_txn_begin(ptr, txnPtrPtr, false).checkNoError();
    try {
      _txnPtr = txnPtrPtr.ptrValue;
      _txnWrite = false;
      return callback(this);
    } finally {
      IsarCore.b.isar_txn_abort(ptr, _txnPtr!);
      _txnPtr = null;
    }
  }

  @override
  T write<T>(T Function(Isar isar) callback) {
    _checkNotInTxn();

    final ptr = getPtr();
    final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
    IsarCore.b.isar_txn_begin(ptr, txnPtrPtr, true).checkNoError();
    try {
      _txnPtr = txnPtrPtr.ptrValue;
      _txnWrite = true;
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
  Future<T> readAsyncWith<T, P>(
    P param,
    T Function(Isar isar, P param) callback, {
    String? debugName,
  }) {
    if (IsarCore.kIsWeb) {
      throw UnsupportedError('Watchers are not supported on the web');
    }

    _checkNotInTxn();

    final instance = instanceId;
    final library = IsarCore._library;
    final schemas = generatedSchemas;
    return runIsolate(
      debugName ?? 'Isar async read',
      () => _isarAsync(
        instanceId: instance,
        schemas: schemas,
        write: false,
        param: param,
        callback: callback,
        library: library,
      ),
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

    final instance = instanceId;
    final library = IsarCore._library;
    final schemas = generatedSchemas.toList();
    return runIsolate(
      debugName ?? 'Isar async write',
      () {
        return _isarAsync(
          instanceId: instance,
          schemas: schemas,
          write: true,
          param: param,
          callback: callback,
          library: library,
        );
      },
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

T _isarAsync<T, P>({
  required int instanceId,
  required List<IsarGeneratedSchema> schemas,
  required bool write,
  required P param,
  required T Function(Isar isar, P param) callback,
  String? library,
}) {
  final isar = _IsarImpl.get(
    instanceId: instanceId,
    schemas: schemas,
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
