part of isar_native;

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;

  final TypeAdapter<OBJ> _adapter;
  final Pointer ptr;
  final List<int> propertyOffsets;
  final int? Function(OBJ) getId;
  final void Function(OBJ, int) setId;

  IsarCollectionImpl(
    this.isar,
    this._adapter,
    this.ptr,
    this.propertyOffsets,
    this.getId,
    this.setId,
  );

  OBJ deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return _adapter.deserialize(this, reader, propertyOffsets);
  }

  List<OBJ> deserializeObjects(RawObjectSet objectSet) {
    final objects = <OBJ>[];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final object = deserializeObject(rawObjPtr.ref);
      objects.add(object);
    }
    return objects;
  }

  Pointer<RawObjectSet> allocRawObjSet(int length) {
    final rawObjSetPtr = malloc<RawObjectSet>();
    final rawObjSet = rawObjSetPtr.ref;
    final objectsPtr = malloc<RawObject>(length);
    rawObjSet.objects = objectsPtr;
    rawObjSet.length = length;
    return rawObjSetPtr;
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(ids.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      for (var i = 0; i < ids.length; i++) {
        objectsPtr.elementAt(i).ref.oid = ids[i];
      }

      IC.isar_get_all(ptr, txnPtr, rawObjSetPtr);
      try {
        await stream.first;
        final objects = <OBJ?>[];
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
        malloc.free(objectsPtr);
        malloc.free(rawObjSetPtr);
      }
    });
  }

  @override
  List<OBJ?> getAllSync(List<int> ids) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        final objects = <OBJ?>[];
        for (var id in ids) {
          rawObj.oid = id;
          nCall(IC.isar_get(ptr, txnPtr, rawObjPtr));
          if (!rawObj.buffer.isNull) {
            objects.add(deserializeObject(rawObj));
          } else {
            objects.add(null);
          }
        }
        return objects;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  Future<void> putAll(List<OBJ> objects) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(objects.length);
      final objectsPtr = rawObjSetPtr.ref.objects;

      for (var i = 0; i < objects.length; i++) {
        final rawObj = objectsPtr.elementAt(i).ref;
        final object = objects[i];
        _adapter.serialize(this, rawObj, object, propertyOffsets);
      }
      IC.isar_put_all(ptr, txnPtr, rawObjSetPtr);

      try {
        await stream.first;
        final rawObjectSet = rawObjSetPtr.ref;
        for (var i = 0; i < objects.length; i++) {
          final rawObjPtr = rawObjectSet.objects.elementAt(i);
          setId(objects[i], rawObjPtr.ref.oid);
        }
      } finally {
        for (var i = 0; i < objects.length; i++) {
          final rawObjPtr = objectsPtr.elementAt(i);
          final rawObj = rawObjPtr.ref;
          rawObj.freeData();
        }
        malloc.free(objectsPtr);
        malloc.free(rawObjSetPtr);
      }
    });
  }

  @override
  void putAllSync(List<OBJ> objects) {
    if (objects.isEmpty) return;
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      int? bufferSize;
      try {
        for (var object in objects) {
          bufferSize = _adapter.serialize(
              this, rawObj, object, propertyOffsets, bufferSize);
          nCall(IC.isar_put(ptr, txnPtr, rawObjPtr));
          setId(object, rawObj.oid);
        }
      } finally {
        rawObj.freeData();
      }
    });
  }

  @override
  Future<int> deleteAll(List<int> ids) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final countPtr = malloc<Uint32>();
      final idsPtr = malloc<Int64>(ids.length);
      idsPtr.asTypedList(ids.length).setAll(0, ids);
      IC.isar_delete_all(ptr, txnPtr, idsPtr, ids.length, countPtr);
      try {
        await stream.first;
        return countPtr.value;
      } finally {
        malloc.free(countPtr);
        malloc.free(idsPtr);
      }
    });
  }

  @override
  int deleteAllSync(List<int> ids) {
    return isar.getTxnSync(true, (txnPtr) {
      final deletedPtr = malloc<Uint8>();
      try {
        var counter = 0;
        for (var id in ids) {
          nCall(IC.isar_delete(ptr, txnPtr, id, deletedPtr));
          if (deletedPtr.value == 1) {
            counter++;
          }
        }
        return counter;
      } finally {
        malloc.free(deletedPtr);
      }
    });
  }

  @override
  Future<void> importJson(Uint8List jsonBytes) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final bytesPtr = malloc<Uint8>(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      IC.isar_json_import(ptr, txnPtr, bytesPtr, jsonBytes.length);

      try {
        await stream.first;
      } finally {
        malloc.free(bytesPtr);
      }
    });
  }

  @override
  Future<R> exportJson<R>(R Function(Uint8List) callback,
      {bool primitiveNull = true, bool includeLinks = false}) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final bytesPtrPtr = malloc<Pointer<Uint8>>();
      final lengthPtr = malloc<Uint32>();
      IC.isar_json_export(
          ptr, txnPtr, primitiveNull, includeLinks, bytesPtrPtr, lengthPtr);

      try {
        await stream.first;
        final bytes = bytesPtrPtr.value.asTypedList(lengthPtr.value);
        return callback(bytes);
      } finally {
        IC.isar_free_json(bytesPtrPtr.value, lengthPtr.value);
        malloc.free(bytesPtrPtr);
        malloc.free(lengthPtr);
      }
    });
  }

  @override
  Stream<void> watchLazy() {
    final port = ReceivePort();
    final handle =
        IC.isar_watch_collection(isar.isarPtr, ptr, port.sendPort.nativePort);
    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });
    controller.addStream(port);
    return controller.stream;
  }

  @override
  Stream<OBJ?> watchObject(int id, {bool initialReturn = false}) {
    return watchObjectLazy(id, initialReturn: initialReturn)
        .asyncMap((event) => get(id));
  }

  @override
  Stream<void> watchObjectLazy(int id, {bool initialReturn = false}) {
    final rawObjPtr = malloc<RawObject>();

    final port = ReceivePort();
    final handle =
        IC.isar_watch_object(isar.isarPtr, ptr, id, port.sendPort.nativePort);
    malloc.free(rawObjPtr);

    final controller = StreamController(onCancel: () {
      IC.isar_stop_watching(handle);
    });

    if (initialReturn) {
      controller.add(true);
    }

    controller.addStream(port);
    return controller.stream;
  }
}
