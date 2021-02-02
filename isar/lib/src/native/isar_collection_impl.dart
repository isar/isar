part of isar_native;

class IsarCollectionImpl<ID, OBJECT> extends IsarCollection<ID, OBJECT> {
  final IsarImpl isar;
  final TypeAdapter<OBJECT> _adapter;
  final Pointer collectionPtr;
  final List<int> propertyOffsets;
  final ID? Function(OBJECT) idGetter;
  final void Function(ID, OBJECT) idSetter;

  IsarCollectionImpl(
    this.isar,
    this._adapter,
    this.collectionPtr,
    this.propertyOffsets,
    this.idGetter,
    this.idSetter,
  );

  List<Pointer> serializeObject(Pointer<RawObject> rawObjPtr, OBJECT object) {
    final rawObj = rawObjPtr.ref;
    _adapter.serialize(rawObj, object, propertyOffsets);
    rawObj.id = idGetter(object);
    if (rawObj.oid_str.address != 0) {
      return [rawObj.oid_str, rawObj.data];
    } else {
      return [rawObj.data];
    }
  }

  List<Pointer> serializeObjects(
      Pointer<RawObjectSet> rawObjSetPtr, List<OBJECT> objects) {
    final pointers = <Pointer>[];
    final rawObjSet = rawObjSetPtr.ref;

    final objectsPtr = calloc<RawObject>(objects.length);
    rawObjSet.objects = objectsPtr;
    rawObjSet.length = objects.length;
    pointers.add(objectsPtr);

    for (var i = 0; i < objects.length; i++) {
      final rawObjPtr = rawObjSet.objects.elementAt(i);
      pointers.addAll(serializeObject(rawObjPtr, objects[i]));
    }
    return pointers;
  }

  OBJECT deserializeObject(RawObject rawObj) {
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final reader = BinaryReader(buffer);
    final object = _adapter.deserialize(reader, propertyOffsets);
    idSetter(rawObj.id, object);
    return object;
  }

  List<OBJECT> deserializeObjects(RawObjectSet objectSet) {
    final objects = <OBJECT>[];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final object = deserializeObject(rawObjPtr.ref);
      objects.add(object);
    }
    return objects;
  }

  @override
  Future<OBJECT?> get(ID id) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjPtr = calloc<RawObject>();
      final rawObj = rawObjPtr.ref;
      rawObj.id = id;

      IC.isar_get_async(collectionPtr, txnPtr, rawObjPtr);
      try {
        await stream.first;

        if (rawObj.id != null) {
          return deserializeObject(rawObj);
        } else {
          return null;
        }
      } finally {
        rawObj.freeId();
        calloc.free(rawObjPtr);
      }
    });
  }

  @override
  OBJECT? getSync(ID id) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.id = id;

      try {
        nCall(IC.isar_get(collectionPtr, txnPtr, rawObjPtr));

        if (rawObj.id != null) {
          return deserializeObject(rawObj);
        } else {
          return null;
        }
      } finally {
        rawObj.freeId();
        calloc.free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> put(OBJECT object) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjPtr = calloc<RawObject>();
      final pointers = serializeObject(rawObjPtr, object);
      IC.isar_put_async(collectionPtr, txnPtr, rawObjPtr);

      try {
        await stream.first;
        idSetter(rawObjPtr.ref.id, object);
      } finally {
        for (var p in pointers) {
          calloc.free(p);
        }
        calloc.free(rawObjPtr);
      }
    });
  }

  @override
  void putSync(OBJECT object) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = calloc<RawObject>();
      final pointers = serializeObject(rawObjPtr, object);

      try {
        nCall(IC.isar_put(collectionPtr, txnPtr, rawObjPtr));
        idSetter(rawObjPtr.ref.id, object);
      } finally {
        for (var p in pointers) {
          calloc.free(p);
        }
        calloc.free(rawObjPtr);
      }
    });
  }

  void updateObjectIds(RawObjectSet rawObjSet, List<OBJECT> objects) {
    for (var i = 0; i < objects.length; i++) {
      final rawObjPtr = rawObjSet.objects.elementAt(i);
      idSetter(rawObjPtr.ref.id!, objects[i]);
    }
  }

  @override
  Future<void> putAll(List<OBJECT> objects) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjSetPtr = calloc<RawObjectSet>();
      final pointers = serializeObjects(rawObjSetPtr, objects);
      IC.isar_put_all_async(collectionPtr, txnPtr, rawObjSetPtr);

      try {
        await stream.first;
        updateObjectIds(rawObjSetPtr.ref, objects);
      } finally {
        for (var p in pointers) {
          calloc.free(p);
        }
        calloc.free(rawObjSetPtr);
      }
    });
  }

  @override
  void putAllSync(List<OBJECT> objects) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjSetPtr = calloc<RawObjectSet>();
      final pointers = serializeObjects(rawObjSetPtr, objects);
      IC.isar_put_all_async(collectionPtr, txnPtr, rawObjSetPtr);

      try {
        nCall(IC.isar_put_all(collectionPtr, txnPtr, rawObjSetPtr));
        updateObjectIds(rawObjSetPtr.ref, objects);
      } finally {
        for (var p in pointers) {
          calloc.free(p);
        }
        calloc.free(rawObjSetPtr);
      }
    });
  }

  @override
  Future<bool> delete(ID id) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final deletedPtr = calloc<Uint8>();
      final rawObjPtr = calloc<RawObject>();
      final rawObj = rawObjPtr.ref;
      rawObj.id = id;
      IC.isar_delete_async(collectionPtr, txnPtr, rawObjPtr, deletedPtr);

      try {
        await stream.first;
        return deletedPtr.value != 0;
      } finally {
        rawObj.freeId();
        calloc.free(rawObjPtr);
        calloc.free(deletedPtr);
      }
    });
  }

  @override
  bool deleteSync(ID id) {
    return isar.getTxnSync(true, (txnPtr) {
      final deletedPtr = calloc<Uint8>();
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.id = id;

      try {
        nCall(IC.isar_delete(collectionPtr, txnPtr, rawObjPtr, deletedPtr));
        return deletedPtr.value != 0;
      } finally {
        rawObj.freeId();
        calloc.free(deletedPtr);
      }
    });
  }

  @override
  Future<void> importJson(Uint8List jsonBytes) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final bytesPtr = calloc<Uint8>(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      IC.isar_json_import_async(
          collectionPtr, txnPtr, bytesPtr, jsonBytes.length);

      try {
        await stream.first;
      } finally {
        calloc.free(bytesPtr);
      }
    });
  }

  @override
  Future<R> exportJson<R>(bool primitiveNull, R Function(Uint8List) callback) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = calloc<Pointer<Uint8>>();
      final lengthPtr = calloc<Uint32>();
      IC.isar_json_export_async(
          collectionPtr, txnPtr, primitiveNull, bytesPtrPtr, lengthPtr);

      try {
        await stream.first;
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        calloc.free(bytesPtrPtr);
        calloc.free(lengthPtr);
      }
    });
  }

  @override
  Stream<void> watchChanges() {
    final port = ReceivePort();
    final handle = IC.isar_watch_collection(
        isar.isarPtr, collectionPtr, port.sendPort.nativePort);
    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });
    controller.addStream(port);
    return controller.stream;
  }

  Stream<void> watchObjectChanges(OBJECT object) {
    final rawObjPtr = calloc<RawObject>();
    final rawObj = rawObjPtr.ref;
    rawObj.id = idGetter(object);

    final port = ReceivePort();
    final handle = IC.isar_watch_object(
        isar.isarPtr, collectionPtr, rawObjPtr, port.sendPort.nativePort);
    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
      rawObj.freeId();
      calloc.free(rawObjPtr);
    });
    controller.addStream(port);
    return controller.stream;
  }
}
