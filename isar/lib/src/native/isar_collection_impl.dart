part of isar_native;

class IsarCollectionImpl<T extends IsarObjectMixin> extends IsarCollection<T> {
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
    throw UnimplementedError();
  }

  @override
  T? getSync(ObjectId id) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      nativeCall(IsarCore.isar_get(collectionPtr, txnPtr, rawObjPtr));

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
    final rawObjPtr = IsarCore.isar_alloc_raw_obj(size);
    final rawObj = rawObjPtr.ref;
    rawObj.oid = object.id;
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final writer = BinaryWriter(buffer, _adapter.staticSize);
    _adapter.serialize(object, cache, writer);
    return rawObjPtr;
  }

  @override
  Future<void> put(T object) {
    throw UnimplementedError();
  }

  @override
  void putSync(T object) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = serializeObject(object);
      final rawObj = rawObjPtr.ref;
      nativeCall(IsarCore.isar_put(collectionPtr, txnPtr, rawObjPtr));

      object.init(rawObj.oid!, this);

      IsarCore.isar_free_raw_obj(rawObjPtr);
    });
  }

  @override
  Future<void> putAll(List<T> objects) {
    throw UnimplementedError();
  }

  @override
  void putAllSync(List<T> objects) {
    /*final rawObjsPtr = allocate<RawObject>(count: objects.length);
    for (var i = 0; i < objects.length; i++) {
      final rawObj = rawObjsPtr.elementAt(i).ref;
      _adapter.serialize(objects[i], rawObj);
    }

    //nativeCall(IsarCore.isar_put_all(_collection, txn, rawObjsPtr));

    for (var i = 0; i < objects.length; i++) {
      final rawObj = rawObjsPtr.elementAt(i).ref;
      objects[i].init(rawObj.oid, this);
    }

    free(rawObjsPtr);*/
  }

  @override
  Future<void> delete(ObjectId id) {
    throw UnimplementedError();
    /*return isar.optionalTxn(true, (txn) {
      var rawObjPtr = IsarCoreUtils.obj;
      var rawObj = rawObjPtr.ref;
      rawObj.oid = object.id;

      nativeCall(IsarCore.isar_delete(_collection, txn, rawObjPtr));
      object.uninit();
    });*/
  }

  @override
  void deleteSync(ObjectId id) {
    return isar.getTxnSync(true, (txnPtr) {
      final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
      final rawObj = rawObjPtr.ref;
      rawObj.oid = id;

      nativeCall(IsarCore.isar_delete(collectionPtr, txnPtr, rawObjPtr));
    });
  }
}
