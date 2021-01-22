part of isar_native;

class IsarCollectionImpl<T extends IsarObject> extends IsarCollection<T> {
  final IsarImpl isar;
  final TypeAdapter<T> _adapter;
  final Pointer collectionPtr;

  IsarCollectionImpl(this.isar, this._adapter, this.collectionPtr);

  void serializeObject(Pointer<RawObject> rawObjPtr, T object) {
    final cache = <String, dynamic>{};
    final size = _adapter.prepareSerialize(object, cache);
    IC.isar_alloc_raw_obj_buffer(rawObjPtr, size);
    final rawObj = rawObjPtr.ref;
    rawObj.oid = object.id;
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final writer = BinaryWriter(buffer, _adapter.staticSize);

    _adapter.serialize(object, cache, writer);
  }

  void serializeObjects(RawObjectSet rawObjSet, List<T> objects) {
    for (var i = 0; i < objects.length; i++) {
      final rawObjPtr = rawObjSet.objects.elementAt(i);
      serializeObject(rawObjPtr, objects[i]);
    }
  }

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
      try {
        await stream.first;

        if (rawObj.oid != null) {
          return deserializeObject(rawObj);
        } else {
          return null;
        }
      } finally {
        free(rawObjPtr);
      }
    });
  }

  @override
  T? getSync(ObjectId id) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      try {
        nCall(IC.isar_get(collectionPtr, txnPtr, rawObjPtr));

        if (rawObj.oid != null) {
          return deserializeObject(rawObj);
        } else {
          return null;
        }
      } finally {
        free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> put(T object) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjPtr = allocate<RawObject>();
      serializeObject(rawObjPtr, object);
      IC.isar_put_async(collectionPtr, txnPtr, rawObjPtr);

      try {
        await stream.first;
        object.init(rawObjPtr.ref.oid!, this);
      } finally {
        IC.isar_free_raw_obj_buffer(rawObjPtr);
        free(rawObjPtr);
      }
    });
  }

  @override
  void putSync(T object) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = allocate<RawObject>();
      serializeObject(rawObjPtr, object);

      try {
        nCall(IC.isar_put(collectionPtr, txnPtr, rawObjPtr));
        object.init(rawObjPtr.ref.oid!, this);
      } finally {
        IC.isar_free_raw_obj_buffer(rawObjPtr);
        free(rawObjPtr);
      }
    });
  }

  void initializeObjectsAndFreeBuffers(
      RawObjectSet rawObjSet, List<T> objects) {
    for (var i = 0; i < objects.length; i++) {
      final rawObjPtr = rawObjSet.objects.elementAt(i);
      objects[i].init(rawObjPtr.ref.oid!, this);
      serializeObject(rawObjPtr, objects[i]);
      IC.isar_free_raw_obj_buffer(rawObjPtr);
    }
  }

  @override
  Future<void> putAll(List<T> objects) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjSetPtr = allocate<RawObjectSet>();
      IC.isar_alloc_raw_obj_list(rawObjSetPtr, objects.length);
      final rawObjSet = rawObjSetPtr.ref;
      serializeObjects(rawObjSet, objects);

      IC.isar_put_all_async(collectionPtr, txnPtr, rawObjSetPtr);

      try {
        await stream.first;
        initializeObjectsAndFreeBuffers(rawObjSetPtr.ref, objects);
      } finally {
        IC.isar_free_raw_obj_list(rawObjSetPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  void putAllSync(List<T> objects) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjSetPtr = allocate<RawObjectSet>();
      IC.isar_alloc_raw_obj_list(rawObjSetPtr, objects.length);
      final rawObjSet = rawObjSetPtr.ref;
      serializeObjects(rawObjSet, objects);

      try {
        nCall(IC.isar_put_all(collectionPtr, txnPtr, rawObjSetPtr));
        initializeObjectsAndFreeBuffers(rawObjSetPtr.ref, objects);
      } finally {
        IC.isar_free_raw_obj_list(rawObjSetPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  Future<bool> delete(ObjectId id) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final deletedPtr = allocate<Uint8>();
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;
      IC.isar_delete_async(collectionPtr, txnPtr, rawObjPtr, deletedPtr);

      try {
        await stream.first;
        return deletedPtr.value != 0;
      } finally {
        free(rawObjPtr);
        free(deletedPtr);
      }
    });
  }

  @override
  bool deleteSync(ObjectId id) {
    return isar.getTxnSync(true, (txnPtr) {
      final deletedPtr = allocate<Uint8>();
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      try {
        nCall(IC.isar_delete(collectionPtr, txnPtr, rawObjPtr, deletedPtr));
        return deletedPtr.value != 0;
      } finally {
        free(deletedPtr);
      }
    });
  }

  @override
  Future<void> importJson(Uint8List jsonBytes) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final bytesPtr = allocate<Uint8>(count: jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      IC.isar_json_import_async(
          collectionPtr, txnPtr, bytesPtr, jsonBytes.length);

      try {
        await stream.first;
      } finally {
        free(bytesPtr);
      }
    });
  }

  @override
  Future<void> exportJson(bool primitiveNull, Function(Uint8List) callback) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = allocate<Pointer<Uint8>>();
      final lengthPtr = allocate<Uint32>();
      IC.isar_json_export_async(
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
  Stream<void> watchChanges() {
    throw UnimplementedError();
  }
}
