part of isar_native;

class IsarCollectionImpl<ID, OBJECT> extends IsarCollection<ID, OBJECT> {
  final IsarImpl isar;
  final TypeAdapter<OBJECT> _adapter;
  final Pointer collectionPtr;
  final List<int> propertyOffsets;
  final ID? Function(OBJECT) getId;
  final void Function(OBJECT, ID) setId;

  IsarCollectionImpl(
    this.isar,
    this._adapter,
    this.collectionPtr,
    this.propertyOffsets,
    this.getId,
    this.setId,
  );

  OBJECT deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return _adapter.deserialize(reader, propertyOffsets);
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

  Pointer<RawObjectSet> allocRawObjSet(int length) {
    final rawObjSetPtr = allocate<RawObjectSet>();
    final rawObjSet = rawObjSetPtr.ref;
    final objectsPtr = allocate<RawObject>(count: length);
    rawObjSet.objects = objectsPtr;
    rawObjSet.length = length;
    return rawObjSetPtr;
  }

  void setRawObjSetIds(Pointer<RawObject> objectsPtr, List<ID> ids) {
    for (var i = 0; i < ids.length; i++) {
      objectsPtr.elementAt(i).ref.id = ids[i];
    }
  }

  void freeRawObjSetIds(Pointer<RawObject> objectsPtr, int length) {
    if (ID is String) {
      for (var i = 0; i < length; i++) {
        objectsPtr.elementAt(i).ref.freeId();
      }
    }
  }

  @override
  Future<List<OBJECT?>> getAll(List<ID> ids) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(ids.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      setRawObjSetIds(objectsPtr, ids);

      IC.isar_get_all_async(collectionPtr, txnPtr, rawObjSetPtr);
      try {
        await stream.first;
        final objects = <OBJECT?>[];
        for (var i = 0; i < ids.length; i++) {
          final rawObj = objectsPtr.elementAt(i).ref;
          if (!rawObj.buffer.isNull) {
            objects.add(deserializeObject(rawObj));
          } else {
            objects.add(null);
          }
        }
        return objects;
      } finally {
        freeRawObjSetIds(objectsPtr, ids.length);
        free(objectsPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  List<OBJECT?> getAllSync(List<ID> ids) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        final objects = <OBJECT?>[];
        for (var id in ids) {
          rawObj.id = id;
          nCall(IC.isar_get(collectionPtr, txnPtr, rawObjPtr));
          if (!rawObj.buffer.isNull) {
            objects.add(deserializeObject(rawObj));
          } else {
            objects.add(null);
          }
          rawObj.freeId();
        }
        return objects;
      } finally {
        free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> putAll(List<OBJECT> objects) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(objects.length);
      final objectsPtr = rawObjSetPtr.ref.objects;

      for (var i = 0; i < objects.length; i++) {
        final rawObj = objectsPtr.elementAt(i).ref;
        final object = objects[i];
        _adapter.serialize(rawObj, object, propertyOffsets);
      }
      IC.isar_put_all_async(collectionPtr, txnPtr, rawObjSetPtr);

      try {
        await stream.first;
        final rawObjectSet = rawObjSetPtr.ref;
        for (var i = 0; i < objects.length; i++) {
          final rawObjPtr = rawObjectSet.objects.elementAt(i);
          if (ID == int) {
            setId(objects[i], rawObjPtr.ref.oid_num as ID);
          }
        }
      } finally {
        for (var i = 0; i < objects.length; i++) {
          final rawObjPtr = objectsPtr.elementAt(i);
          final rawObj = rawObjPtr.ref;
          rawObj.freeData();
        }
        free(objectsPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  void putAllSync(List<OBJECT> objects) {
    if (objects.isEmpty) return;
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      int? bufferSize;
      try {
        for (var object in objects) {
          bufferSize =
              _adapter.serialize(rawObj, object, propertyOffsets, bufferSize);
          nCall(IC.isar_put(collectionPtr, txnPtr, rawObjPtr));
          if (ID == int) {
            setId(object, rawObj.oid_num as ID);
          }
        }
      } finally {
        rawObj.freeData();
      }
    });
  }

  @override
  Future<int> deleteAll(List<ID> ids) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final countPtr = allocate<Uint32>();
      final rawObjSetPtr = allocRawObjSet(ids.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      setRawObjSetIds(objectsPtr, ids);

      IC.isar_delete_all_async(collectionPtr, txnPtr, rawObjSetPtr, countPtr);
      try {
        await stream.first;
        return countPtr.value;
      } finally {
        freeRawObjSetIds(objectsPtr, ids.length);
        free(objectsPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  int deleteAllSync(List<ID> ids) {
    return isar.getTxnSync(true, (txnPtr) {
      final deletedPtr = allocate<Uint8>();
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        var counter = 0;
        for (var id in ids) {
          rawObj.id = id;
          nCall(IC.isar_delete(collectionPtr, txnPtr, rawObjPtr, deletedPtr));
          if (deletedPtr.value == 1) {
            counter++;
          }
        }
        return counter;
      } finally {
        free(rawObjPtr);
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
  Future<R> exportJson<R>(bool primitiveNull, R Function(Uint8List) callback) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = allocate<Pointer<Uint8>>();
      final lengthPtr = allocate<Uint32>();
      IC.isar_json_export_async(
          collectionPtr, txnPtr, primitiveNull, bytesPtrPtr, lengthPtr);

      try {
        await stream.first;
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        free(bytesPtrPtr);
        free(lengthPtr);
      }
    });
  }

  @override
  Stream<OBJECT?> watch({ID? id, bool lazy = true}) {
    if (id == null) {
      assert(lazy);
      return _watchCollection().map((event) => null);
    } else {
      return _watchObject(id, lazy: lazy);
    }
  }

  Stream<void> _watchCollection() {
    final port = ReceivePort();
    final handle = IC.isar_watch_collection(
        isar.isarPtr, collectionPtr, port.sendPort.nativePort);
    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });
    controller.addStream(port);
    return controller.stream;
  }

  Stream<OBJECT?> _watchObject(ID id, {bool lazy = true}) {
    final rawObjPtr = allocate<RawObject>();
    final rawObj = rawObjPtr.ref;
    rawObj.id = id;

    final port = ReceivePort();
    final handle = IC.isar_watch_object(
        isar.isarPtr, collectionPtr, rawObjPtr, port.sendPort.nativePort);
    rawObj.freeId();
    free(rawObjPtr);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    controller.addStream(port);

    if (lazy) {
      return controller.stream.map((event) => null);
    } else {
      return controller.stream.asyncMap((event) => get(id));
    }
  }
}
