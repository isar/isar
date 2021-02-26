part of isar_native;

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  final IsarImpl isar;
  final TypeAdapter<OBJ> _adapter;
  final Pointer collectionPtr;
  final List<int> propertyOffsets;
  final int? Function(OBJ) getId;
  final void Function(OBJ, int) setId;

  IsarCollectionImpl(
    this.isar,
    this._adapter,
    this.collectionPtr,
    this.propertyOffsets,
    this.getId,
    this.setId,
  );

  OBJ deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return _adapter.deserialize(reader, propertyOffsets);
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
    final rawObjSetPtr = allocate<RawObjectSet>();
    final rawObjSet = rawObjSetPtr.ref;
    final objectsPtr = allocate<RawObject>(count: length);
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

      IC.isar_get_all_async(collectionPtr, txnPtr, rawObjSetPtr);
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
        free(objectsPtr);
        free(rawObjSetPtr);
      }
    });
  }

  @override
  List<OBJ?> getAllSync(List<int> ids) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = allocate<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        final objects = <OBJ?>[];
        for (var id in ids) {
          rawObj.oid = id;
          nCall(IC.isar_get(collectionPtr, txnPtr, rawObjPtr));
          if (!rawObj.buffer.isNull) {
            objects.add(deserializeObject(rawObj));
          } else {
            objects.add(null);
          }
        }
        return objects;
      } finally {
        free(rawObjPtr);
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
        _adapter.serialize(rawObj, object, propertyOffsets);
      }
      IC.isar_put_all_async(collectionPtr, txnPtr, rawObjSetPtr);

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
        free(objectsPtr);
        free(rawObjSetPtr);
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
          bufferSize =
              _adapter.serialize(rawObj, object, propertyOffsets, bufferSize);
          nCall(IC.isar_put(collectionPtr, txnPtr, rawObjPtr));
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
      final countPtr = allocate<Uint32>();
      final idsPtr = allocate<Int64>(count: ids.length);
      idsPtr.asTypedList(ids.length).setAll(0, ids);
      IC.isar_delete_all_async(
          collectionPtr, txnPtr, idsPtr, ids.length, countPtr);
      try {
        await stream.first;
        return countPtr.value;
      } finally {
        free(countPtr);
        free(idsPtr);
      }
    });
  }

  @override
  int deleteAllSync(List<int> ids) {
    return isar.getTxnSync(true, (txnPtr) {
      final deletedPtr = allocate<Uint8>();
      try {
        var counter = 0;
        for (var id in ids) {
          nCall(IC.isar_delete(collectionPtr, txnPtr, id, deletedPtr));
          if (deletedPtr.value == 1) {
            counter++;
          }
        }
        return counter;
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
  Stream<OBJ?> watch({int? id, bool lazy = true}) {
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

  Stream<OBJ?> _watchObject(int id, {bool lazy = true}) {
    final rawObjPtr = allocate<RawObject>();

    final port = ReceivePort();
    final handle = IC.isar_watch_object(
        isar.isarPtr, collectionPtr, id, port.sendPort.nativePort);
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
