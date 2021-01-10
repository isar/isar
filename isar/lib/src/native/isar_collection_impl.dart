part of isar_native;

class IsarCollectionImpl<T extends IsarObject> extends IsarCollection<T> {
  final IsarImpl isar;
  final TypeAdapter<T> _adapter;
  final Pointer collectionPtr;

  IsarCollectionImpl(this.isar, this._adapter, this.collectionPtr);

  T deserializeObject(RawObject rawObj) {
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final reader = BinaryReader(buffer);
    final object = _adapter.deserialize(reader);
    object.init(rawObj.oid!, this);
    return object;
  }

  List<T> deserializeObjects(RawObjectSet objectSet) {
    final objects = <T>[];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final object = deserializeObject(rawObjPtr.ref);
      objects.add(object);
    }
    return objects;
  }

  @override
  Future<T?> get(ObjectId id) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      IC.isar_get_async(collectionPtr, txnPtr, rawObjPtr);
      await stream.first;

      if (rawObj.oid != null) {
        return deserializeObject(rawObj);
      } else {
        return null;
      }
    });
  }

  @override
  T? getSync(ObjectId id) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      nCall(IC.isar_get(collectionPtr, txnPtr, rawObjPtr));

      if (rawObj.oid != null) {
        return deserializeObject(rawObj);
      } else {
        return null;
      }
    });
  }

  Pointer<RawObject> serializeObject(T object) {
    final cache = <String, dynamic>{};
    final size = _adapter.prepareSerialize(object, cache);
    final rawObjPtr = IC.isar_alloc_raw_obj(size);
    final rawObj = rawObjPtr.ref;
    rawObj.oid = object.id;
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final writer = BinaryWriter(buffer, _adapter.staticSize);
    _adapter.serialize(object, cache, writer);
    return rawObjPtr;
  }

  @override
  Future<void> put(T object) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjPtr = serializeObject(object);
      final rawObj = rawObjPtr.ref;
      IC.isar_put_async(collectionPtr, txnPtr, rawObjPtr);

      try {
        await stream.first;
        object.init(rawObj.oid!, this);
      } finally {
        IC.isar_free_raw_obj(rawObjPtr);
      }
    });
  }

  @override
  void putSync(T object) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = serializeObject(object);
      final rawObj = rawObjPtr.ref;

      try {
        nCall(IC.isar_put(collectionPtr, txnPtr, rawObjPtr));
        object.init(rawObj.oid!, this);
      } finally {
        IC.isar_free_raw_obj(rawObjPtr);
      }
    });
  }

  @override
  Future<void> putAll(List<T> objects) {
    throw UnimplementedError();
  }

  @override
  void putAllSync(List<T> objects) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(ObjectId id) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;
      IC.isar_delete_async(collectionPtr, txnPtr, rawObjPtr);

      try {
        await stream.first;
      } finally {
        free(rawObjPtr);
      }
    });
  }

  @override
  void deleteSync(ObjectId id) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      nCall(IC.isar_delete(collectionPtr, txnPtr, rawObjPtr));
    });
  }

  @override
  Future<void> exportJson(bool primitiveNull, Function(Uint8List) callback) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = allocate<Pointer<Uint8>>();
      final lengthPtr = allocate<Uint32>();
      IC.isar_export_json_async(
          collectionPtr, txnPtr, primitiveNull, bytesPtrPtr, lengthPtr);

      try {
        await stream.first;
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        free(bytesPtrPtr);
        free(lengthPtr);
      }
    });
  }

  @override
  void exportJsonSync(bool primitiveNull, Function(Uint8List) callback) {
    return isar.getTxnSync(false, (txnPtr) {
      final bytesPtrPtr = allocate<Pointer<Uint8>>();
      final lengthPtr = allocate<Uint32>();

      try {
        nCall(IC.isar_export_json(
            collectionPtr, txnPtr, primitiveNull, bytesPtrPtr, lengthPtr));
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        free(bytesPtrPtr);
        free(lengthPtr);
      }
    });
  }
}
