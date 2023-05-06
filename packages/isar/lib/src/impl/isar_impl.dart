part of isar;

class _IsarImpl implements Isar {
  _IsarImpl._(this.ptr, this.converters) {
    for (var i = 0; i < converters.length; i++) {
      final converter = converters[i];
      collections[converter.type] = converters[i].withType(
        <ID, OBJ>(ObjectConverter<ID, OBJ> converter) {
          return _IsarCollectionImpl<ID, OBJ>(this, i, converter);
        },
      );
    }
  }

  final Pointer<CIsarInstance> ptr;
  final List<ObjectConverter<dynamic, dynamic>> converters;

  final collections = <Type, _IsarCollectionImpl<dynamic, dynamic>>{};

  Pointer<CIsarTxn>? _txnPtr;
  bool _txnWrite = false;

  factory _IsarImpl.get({
    required List<ObjectConverter<dynamic, dynamic>> converters,
    required String name,
  }) {
    final instance = IsarCore.isar_get(Isar.fastHash(name));
    if (instance.isNull) {
      throw IsarError('Instance $name has not been opened yet. Make sure to '
          'call Isar.open() before calling Isar.get().');
    }

    return _IsarImpl._(instance, converters);
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
    IsarCore.isar_open(
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
    return _IsarImpl._(isarPtrPtr.value, converters);
  }

  T getTxn<T>(T Function(Pointer<CIsarTxn> txnPtr) callback) {
    final txnPtr = _txnPtr;
    if (txnPtr != null) {
      return callback(txnPtr);
    } else {
      return _txn(write: false, (isar) => callback(_txnPtr!));
    }
  }

  T getWriteTxn<T>(
    (T, Pointer<CIsarTxn>?) Function(Pointer<CIsarTxn> txnPtr) callback, {
    bool consume = false,
  }) {
    final txnPtr = _txnPtr;
    if (txnPtr != null) {
      if (_txnWrite) {
        if (consume) {
          _txnPtr = null;
        }
        final (result, returnedPtr) = callback(txnPtr);
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

    final txnPtrPtr = IsarCore.ptrPtr.cast<Pointer<CIsarTxn>>();
    IsarCore.isar_txn_begin(ptr, txnPtrPtr, write).checkNoError();
    try {
      _txnPtr = txnPtrPtr.value;
      _txnWrite = write;
      final result = callback(this);
      IsarCore.isar_txn_commit(ptr, _txnPtr!).checkNoError();
      return result;
    } catch (_) {
      final txnPtr = _txnPtr;
      if (txnPtr != null) {
        IsarCore.isar_txn_abort(ptr, txnPtr);
      }
      rethrow;
    } finally {
      _txnPtr = null;
    }
  }

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
    // TODO: implement clear
  }
}
