import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:isar/internal.dart';
import 'package:isar/internal_native.dart';
import 'package:isar/src/isar_collection.dart';
import 'package:isar/src/isar_object.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';
import 'package:isar/src/native/type_adapter.dart';
import 'package:isar/src/native/util/native_call.dart';
import 'package:isar/src/object_id.dart';

class IsarCollectionImpl<T extends IsarObject> extends IsarCollection<T> {
  final IsarImpl isar;
  final TypeAdapter<T> _adapter;
  final Pointer _collection;

  IsarCollectionImpl(this.isar, this._adapter, this._collection);

  T deserializeObject(RawObject rawObj) {
    final buffer = rawObj.data.asTypedList(rawObj.data_length);
    final reader = BinaryReader(buffer);
    final object = _adapter.deserialize(reader);
    object.init(rawObj.oid, this);
    return object;
  }

  @override
  Future<T> get(ObjectId id) {
    throw UnimplementedError();
  }

  @override
  T getSync(ObjectId id) {
    final txn = isar.getTxnSync(false);

    final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
    final rawObj = rawObjPtr.ref;
    rawObj.oid = id;

    nativeCall(IsarCore.isar_get(_collection, txn!, rawObjPtr));
    return deserializeObject(rawObj);
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
    final txn = isar.getTxnSync(true);

    final rawObjPtr = serializeObject(object);
    final rawObj = rawObjPtr.ref;
    nativeCall(IsarCore.isar_put(_collection, txn!, rawObjPtr));

    object.init(rawObj.oid, this);

    IsarCore.isar_free_raw_obj(rawObjPtr);
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
  Future<void> delete(T object) {
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
  void deleteSync(T object) {
    final txn = isar.getTxnSync(true);

    final rawObjPtr = IsarCoreUtils.syncRawObjPtr;
    final rawObj = rawObjPtr.ref;
    rawObj.oid = object.id;

    nativeCall(IsarCore.isar_delete(_collection, txn!, rawObjPtr));
    object.uninit();
  }
}
