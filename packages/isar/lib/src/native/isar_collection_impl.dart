part of isar_native;

enum NativeIndexType {
  Bool,
  Int,
  Float,
  Long,
  Double,
  StringHash,
  StringHashCIS,
  StringValue,
  StringValueCIS,
  StringWords,
  StringWordsCIS,
}

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;

  final TypeAdapter<OBJ> adapter;
  final Pointer ptr;

  final List<int> propertyOffsets;
  final Map<String, int> propertyIds;
  final Map<String, int> indexIds;
  final Map<String, List<NativeIndexType>> indexTypes;
  final Map<String, int> linkIds;
  final Map<String, int> backlinkIds;
  final int? Function(OBJ) getId;

  IsarCollectionImpl({
    required this.isar,
    required this.adapter,
    required this.ptr,
    required this.propertyOffsets,
    required this.propertyIds,
    required this.indexIds,
    required this.indexTypes,
    required this.linkIds,
    required this.backlinkIds,
    required this.getId,
  });

  OBJ deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return adapter.deserialize(this, reader, propertyOffsets);
  }

  OBJ? deserializeObjectOrNull(RawObject rawObj) {
    if (!rawObj.buffer.isNull) {
      return deserializeObject(rawObj);
    } else {
      return null;
    }
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

  List<OBJ?> deserializeObjectsOrNull(RawObjectSet objectSet) {
    final objects = <OBJ?>[];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final rawObj = rawObjPtr.ref;
      if (!rawObj.buffer.isNull) {
        objects.add(deserializeObject(rawObj));
      } else {
        objects.add(null);
      }
    }
    return objects;
  }

  Pointer<Pointer<NativeType>> _getKeysPtr(
      String indexProperty, List<List<dynamic>> values) {
    final keysPtrPtr = malloc<Pointer>(values.length);
    for (var i = 0; i < values.length; i++) {
      keysPtrPtr[i] = buildIndexKey(this, indexProperty, values[i]);
    }
    return keysPtrPtr;
  }

  List<T> deserializeProperty<T>(RawObjectSet objectSet, int propertyIndex) {
    final values = <T>[];
    final propertyOffset = propertyOffsets[propertyIndex];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final rawObj = rawObjPtr.ref;
      final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
      final reader = BinaryReader(buffer);
      values.add(adapter.deserializeProperty(
        reader,
        propertyIndex,
        propertyOffset,
      ));
    }
    return values;
  }

  Pointer<RawObjectSet> allocRawObjSet(int length) {
    final rawObjSetPtr = malloc<RawObjectSet>();
    final rawObjSet = rawObjSetPtr.ref;
    final objectsPtr = malloc<RawObject>(length);
    rawObjSet.objects = objectsPtr;
    rawObjSet.length = length;
    return rawObjSetPtr;
  }

  Future<List<OBJ?>> _getAll(
      List<int>? ids, String? indexProperty, List<List>? values) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final length = (ids ?? values)!.length;
      final rawObjSetPtr = allocRawObjSet(length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      var keysPtrPtr = Pointer<Pointer<NativeType>>.fromAddress(0);

      if (ids != null) {
        for (var i = 0; i < ids.length; i++) {
          objectsPtr.elementAt(i).ref.id = ids[i];
        }
      } else {
        keysPtrPtr = _getKeysPtr(indexProperty!, values!);
      }

      IC.isar_get_all(ptr, txnPtr, rawObjSetPtr, keysPtrPtr);
      try {
        await stream.first;
        return deserializeObjectsOrNull(rawObjSetPtr.ref);
      } finally {
        malloc.free(objectsPtr);
        malloc.free(rawObjSetPtr);
      }
    });
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return _getAll(ids, null, null);
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexProperty, List<List> values) {
    return _getAll(null, indexProperty, values);
  }

  List<OBJ?> _getAllSync(List<int>? ids, String? indexProperty, List? values) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        final objects = <OBJ?>[];
        if (ids != null) {
          final nullPtr = Pointer.fromAddress(0);
          for (var id in ids) {
            rawObj.id = id;
            nCall(IC.isar_get(ptr, txnPtr, rawObjPtr, nullPtr));
            objects.add(deserializeObjectOrNull(rawObj));
          }
        } else {
          for (var value in values!) {
            final keyPtr = buildIndexKey(this, indexProperty!, value);
            nCall(IC.isar_get(ptr, txnPtr, rawObjPtr, keyPtr));
            objects.add(deserializeObjectOrNull(rawObj));
          }
        }

        return objects;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  List<OBJ?> getAllSync(List<int> ids) {
    return _getAllSync(ids, null, null);
  }

  @override
  List<OBJ?> getAllByIndexSync(String indexProperty, List values) {
    return _getAllSync(null, indexProperty, values);
  }

  @override
  Future<List<int>> putAll(List<OBJ> objects) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(objects.length);
      final objectsPtr = rawObjSetPtr.ref.objects;

      for (var i = 0; i < objects.length; i++) {
        final rawObj = objectsPtr.elementAt(i).ref;
        final object = objects[i];
        adapter.serialize(this, rawObj, object, propertyOffsets);
      }
      IC.isar_put_all(ptr, txnPtr, rawObjSetPtr);

      try {
        await stream.first;
        final rawObjectSet = rawObjSetPtr.ref;
        final ids = <int>[];
        for (var i = 0; i < objects.length; i++) {
          final rawObjPtr = rawObjectSet.objects.elementAt(i);
          ids.add(rawObjPtr.ref.id);
        }
        return ids;
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
  List<int> putAllSync(List<OBJ> objects) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      int? bufferSize;
      try {
        final ids = <int>[];
        for (var object in objects) {
          bufferSize = adapter.serialize(
              this, rawObj, object, propertyOffsets, bufferSize);
          print(rawObj.id);
          nCall(IC.isar_put(ptr, txnPtr, rawObjPtr));
          ids.add(rawObj.id);
        }
        return ids;
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
      IC.isar_delete_all(ptr, txnPtr, idsPtr, IsarCoreUtils.nullPtr.cast(),
          ids.length, countPtr);
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
  Future<int> deleteAllByIndex(String indexProperty, List<List> values) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final countPtr = malloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexProperty, values);
      IC.isar_delete_all(ptr, txnPtr, IsarCoreUtils.nullPtr.cast(), keysPtrPtr,
          values.length, countPtr);
      try {
        await stream.first;
        return countPtr.value;
      } finally {
        malloc.free(countPtr);
        malloc.free(keysPtrPtr);
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
          nCall(IC.isar_delete(
              ptr, txnPtr, id, IsarCoreUtils.nullPtr, deletedPtr));
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
  int deleteAllByIndexSync(String indexProperty, List<List> values) {
    return isar.getTxnSync(true, (txnPtr) {
      final countPtr = malloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexProperty, values);
      try {
        nCall(IC.isar_delete_all(ptr, txnPtr, IsarCoreUtils.nullPtr.cast(),
            keysPtrPtr, values.length, countPtr));
        return countPtr.value;
      } finally {
        malloc.free(countPtr);
        malloc.free(keysPtrPtr);
      }
    });
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) {
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
  Stream<void> watchLazy() {
    isar.requireOpen();
    final port = ReceivePort();
    final handle =
        IC.isar_watch_collection(isar.ptr, ptr, port.sendPort.nativePort);
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
    isar.requireOpen();
    final rawObjPtr = malloc<RawObject>();

    final port = ReceivePort();
    final handle =
        IC.isar_watch_object(isar.ptr, ptr, id, port.sendPort.nativePort);
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

  @override
  Query<T> buildQuery<T>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.Asc,
    FilterGroup? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    isar.requireOpen();
    return buildNativeQuery(
      this,
      whereClauses,
      whereDistinct,
      whereSort,
      filter,
      sortBy,
      distinctBy,
      offset,
      limit,
      property,
    );
  }
}
