// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:isar/isar.dart';
import 'package:isar/src/native/binary_reader.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/index_key.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';
import 'package:isar/src/native/query_build.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  IsarCollectionImpl({
    required this.isar,
    required this.ptr,
    required this.schema,
    required int staticSize,
    required List<int> offsets,
  })  : _staticSize = staticSize,
        _offsets = offsets;
  @override
  final IsarImpl isar;
  final Pointer<CIsarCollection> ptr;

  final CollectionSchema<OBJ> schema;
  final int _staticSize;
  final List<int> _offsets;

  @override
  String get name => schema.name;

  @override
  String get idName => schema.idName;

  @pragma('vm:prefer-inline')
  OBJ deserializeObject(CObject cObj) {
    final buffer = cObj.buffer.asTypedList(cObj.buffer_length);
    final reader = BinaryReader(buffer);
    return schema.deserializeNative(this, cObj.id, reader, _offsets);
  }

  @pragma('vm:prefer-inline')
  OBJ? deserializeObjectOrNull(CObject cObj) {
    if (!cObj.buffer.isNull) {
      return deserializeObject(cObj);
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  List<OBJ> deserializeObjects(CObjectSet objectSet) {
    final objects = <OBJ>[];
    for (var i = 0; i < objectSet.length; i++) {
      final cObjPtr = objectSet.objects.elementAt(i);
      final object = deserializeObject(cObjPtr.ref);
      objects.add(object);
    }
    return objects;
  }

  @pragma('vm:prefer-inline')
  List<OBJ?> deserializeObjectsOrNull(CObjectSet objectSet) {
    final objects = List<OBJ?>.filled(objectSet.length, null);
    for (var i = 0; i < objectSet.length; i++) {
      final cObj = objectSet.objects.elementAt(i).ref;
      if (!cObj.buffer.isNull) {
        objects[i] = deserializeObject(cObj);
      }
    }
    return objects;
  }

  @pragma('vm:prefer-inline')
  Pointer<Pointer<CIndexKey>> _getKeysPtr(
    String indexName,
    List<IndexKey> keys,
    Allocator alloc,
  ) {
    final keysPtrPtr = alloc<Pointer<CIndexKey>>(keys.length);
    for (var i = 0; i < keys.length; i++) {
      keysPtrPtr[i] = buildIndexKey(
        schema,
        indexName,
        keys[i],
        requireFullKey: true,
      )!;
    }
    return keysPtrPtr;
  }

  List<T> deserializeProperty<T>(CObjectSet objectSet, int? propertyIndex) {
    final values = <T>[];
    if (propertyIndex != null) {
      final propertyOffset = _offsets[propertyIndex];
      for (var i = 0; i < objectSet.length; i++) {
        final cObj = objectSet.objects.elementAt(i).ref;
        final buffer = cObj.buffer.asTypedList(cObj.buffer_length);
        values.add(
          schema.deserializePropNative(
            cObj.id,
            BinaryReader(buffer),
            propertyIndex,
            propertyOffset,
          ) as T,
        );
      }
    } else {
      for (var i = 0; i < objectSet.length; i++) {
        final cObj = objectSet.objects.elementAt(i).ref;
        values.add(cObj.id as T);
      }
    }
    return values;
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txn) async {
      final cObjSetPtr = txn.allocCObjectSet(ids.length);
      final objectsPtr = cObjSetPtr.ref.objects;
      for (var i = 0; i < ids.length; i++) {
        objectsPtr.elementAt(i).ref.id = ids[i];
      }
      IC.isar_get_all(ptr, txn.ptr, cObjSetPtr);
      await txn.wait();
      return deserializeObjectsOrNull(cObjSetPtr.ref);
    });
  }

  @override
  List<OBJ?> getAllSync(List<int> ids) {
    return isar.getTxnSync(false, (txn) {
      final cObjPtr = txn.allocCObject();
      final cObj = cObjPtr.ref;

      final objects = List<OBJ?>.filled(ids.length, null);
      for (var i = 0; i < ids.length; i++) {
        cObj.id = ids[i];
        nCall(IC.isar_get(ptr, txn.ptr, cObjPtr));
        objects[i] = deserializeObjectOrNull(cObj);
      }

      return objects;
    });
  }

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(false, (txn) async {
      final cObjSetPtr = txn.allocCObjectSet(keys.length);
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);
      IC.isar_get_all_by_index(
        ptr,
        txn.ptr,
        schema.indexIdOrErr(indexName),
        keysPtrPtr,
        cObjSetPtr,
      );
      await txn.wait();
      return deserializeObjectsOrNull(cObjSetPtr.ref);
    });
  }

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys) {
    final indexId = schema.indexIdOrErr(indexName);

    return isar.getTxnSync(false, (txn) {
      final cObjPtr = txn.allocCObject();
      final cObj = cObjPtr.ref;

      final objects = List<OBJ?>.filled(keys.length, null);
      for (var i = 0; i < keys.length; i++) {
        final keyPtr = buildIndexKey(
          schema,
          indexName,
          keys[i],
          requireFullKey: true,
        )!;
        nCall(IC.isar_get_by_index(ptr, txn.ptr, indexId, keyPtr, cObjPtr));
        objects[i] = deserializeObjectOrNull(cObj);
      }

      return objects;
    });
  }

  @override
  int putSync(OBJ object, {bool saveLinks = true}) {
    return isar.getTxnSync(true, (txn) {
      return putByIndexSyncInternal(
        txn: txn,
        object: object,
        saveLinks: saveLinks,
      );
    });
  }

  @override
  int putByIndexSync(String indexName, OBJ object, {bool saveLinks = true}) {
    return isar.getTxnSync(true, (txn) {
      return putByIndexSyncInternal(
        txn: txn,
        object: object,
        indexId: schema.indexIdOrErr(indexName),
        saveLinks: saveLinks,
      );
    });
  }

  int putByIndexSyncInternal({
    required SyncTxn txn,
    int? indexId,
    required OBJ object,
    bool saveLinks = true,
  }) {
    final cObjPtr = txn.allocCObject();
    final cObj = cObjPtr.ref;

    schema.serializeNative(
      this,
      cObj,
      object,
      _staticSize,
      _offsets,
      txn.allocBuffer,
    );
    cObj.id = schema.getId(object) ?? Isar.autoIncrement;

    if (indexId != null) {
      nCall(IC.isar_put_by_index(ptr, txn.ptr, indexId, cObjPtr));
    } else {
      nCall(IC.isar_put(ptr, txn.ptr, cObjPtr));
    }

    final id = cObj.id;
    schema.setId?.call(object, id);

    if (schema.hasLinks) {
      schema.attachLinks(this, id, object);
      if (saveLinks) {
        for (final link in schema.getLinks(object)) {
          link.saveSync();
        }
      }
    }

    return id;
  }

  @override
  Future<List<int>> putAll(List<OBJ> objects) {
    return putAllByIndex(null, objects);
  }

  @override
  List<int> putAllSync(List<OBJ> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(null, objects);
  }

  @override
  Future<List<int>> putAllByIndex(String? indexName, List<OBJ> objects) {
    final indexId = indexName != null ? schema.indexIdOrErr(indexName) : null;

    return isar.getTxn(true, (txn) async {
      final cObjSetPtr = txn.allocCObjectSet(objects.length);
      final objectsPtr = cObjSetPtr.ref.objects;

      Pointer<Uint8> allocBuf(int size) => txn.alloc<Uint8>(size);
      for (var i = 0; i < objects.length; i++) {
        final object = objects[i];
        final cObj = objectsPtr.elementAt(i).ref;
        schema.serializeNative(
          this,
          cObj,
          object,
          _staticSize,
          _offsets,
          allocBuf,
        );
        cObj.id = schema.getId(object) ?? Isar.autoIncrement;
      }
      if (indexId != null) {
        IC.isar_put_all_by_index(ptr, txn.ptr, indexId, cObjSetPtr);
      } else {
        IC.isar_put_all(ptr, txn.ptr, cObjSetPtr);
      }

      await txn.wait();
      final cObjectSet = cObjSetPtr.ref;
      final ids = List<int>.filled(objects.length, 0);
      for (var i = 0; i < objects.length; i++) {
        final cObjPtr = cObjectSet.objects.elementAt(i);
        final id = cObjPtr.ref.id;
        ids[i] = id;

        final object = objects[i];
        schema.setId?.call(object, id);
        schema.attachLinks(this, id, object);
      }
      return ids;
    });
  }

  @override
  List<int> putAllByIndexSync(
    String? indexName,
    List<OBJ> objects, {
    bool saveLinks = true,
  }) {
    final indexId = indexName != null ? schema.indexIdOrErr(indexName) : null;
    final ids = List.filled(objects.length, 0);
    isar.getTxnSync(true, (txn) {
      for (var i = 0; i < objects.length; i++) {
        ids[i] = putByIndexSyncInternal(
          txn: txn,
          object: objects[i],
          indexId: indexId,
          saveLinks: saveLinks,
        );
      }
    });
    return ids;
  }

  @override
  Future<int> deleteAll(List<int> ids) {
    return isar.getTxn(true, (txn) async {
      final countPtr = txn.alloc<Uint32>();
      final idsPtr = txn.alloc<Int64>(ids.length);
      idsPtr.asTypedList(ids.length).setAll(0, ids);

      IC.isar_delete_all(ptr, txn.ptr, idsPtr, ids.length, countPtr);
      await txn.wait();

      return countPtr.value;
    });
  }

  @override
  int deleteAllSync(List<int> ids) {
    return isar.getTxnSync(true, (txn) {
      final deletedPtr = txn.alloc<Bool>();

      var counter = 0;
      for (final id in ids) {
        nCall(IC.isar_delete(ptr, txn.ptr, id, deletedPtr));
        if (deletedPtr.value) {
          counter++;
        }
      }
      return counter;
    });
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(true, (txn) async {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      IC.isar_delete_all_by_index(
        ptr,
        txn.ptr,
        schema.indexIdOrErr(indexName),
        keysPtrPtr,
        keys.length,
        countPtr,
      );
      await txn.wait();

      return countPtr.value;
    });
  }

  @override
  int deleteAllByIndexSync(String indexName, List<IndexKey> keys) {
    return isar.getTxnSync(true, (txn) {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      nCall(
        IC.isar_delete_all_by_index(
          ptr,
          txn.ptr,
          schema.indexIdOrErr(indexName),
          keysPtrPtr,
          keys.length,
          countPtr,
        ),
      );
      return countPtr.value;
    });
  }

  @override
  Future<void> clear() {
    return isar.getTxn(true, (txn) async {
      IC.isar_clear(ptr, txn.ptr);
      await txn.wait();
    });
  }

  @override
  void clearSync() {
    isar.getTxnSync(true, (txn) {
      nCall(IC.isar_clear(ptr, txn.ptr));
    });
  }

  @override
  Future<void> importJson(List<Map<String, dynamic>> json) {
    final bytes = const Utf8Encoder().convert(jsonEncode(json));
    return importJsonRaw(bytes);
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes) {
    return isar.getTxn(true, (txn) async {
      final bytesPtr = txn.alloc<Uint8>(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toNativeUtf8(allocator: txn.alloc);

      IC.isar_json_import(
        ptr,
        txn.ptr,
        idNamePtr.cast(),
        bytesPtr,
        jsonBytes.length,
      );
      await txn.wait();
    });
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json) {
    final bytes = const Utf8Encoder().convert(jsonEncode(json));
    importJsonRawSync(bytes);
  }

  @override
  void importJsonRawSync(Uint8List jsonBytes) {
    return isar.getTxnSync(true, (txn) async {
      final bytesPtr = txn.allocBuffer(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toNativeUtf8(allocator: txn.alloc);

      nCall(
        IC.isar_json_import(
          ptr,
          txn.ptr,
          idNamePtr.cast(),
          bytesPtr,
          jsonBytes.length,
        ),
      );
    });
  }

  @override
  Future<int> count() {
    return isar.getTxn(false, (txn) async {
      final countPtr = txn.alloc<Int64>();
      IC.isar_count(ptr, txn.ptr, countPtr);
      await txn.wait();
      return countPtr.value;
    });
  }

  @override
  int countSync() {
    return isar.getTxnSync(false, (txn) {
      final countPtr = txn.alloc<Int64>();
      nCall(IC.isar_count(ptr, txn.ptr, countPtr));
      return countPtr.value;
    });
  }

  @override
  Future<int> getSize({
    bool includeIndexes = false,
    bool includeLinks = false,
  }) {
    return isar.getTxn(false, (txn) async {
      final sizePtr = txn.alloc<Int64>();
      IC.isar_get_size(ptr, txn.ptr, includeIndexes, includeLinks, sizePtr);
      await txn.wait();
      return sizePtr.value;
    });
  }

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) {
    return isar.getTxnSync(false, (txn) {
      final sizePtr = txn.alloc<Int64>();
      nCall(
        IC.isar_get_size(
          ptr,
          txn.ptr,
          includeIndexes,
          includeLinks,
          sizePtr,
        ),
      );
      return sizePtr.value;
    });
  }

  @override
  Stream<void> watchLazy() {
    // ignore: invalid_use_of_protected_member
    isar.requireOpen();
    final port = ReceivePort();
    final handle =
        IC.isar_watch_collection(isar.ptr, ptr, port.sendPort.nativePort);
    final controller = StreamController<void>(
      onCancel: () {
        IC.isar_stop_watching(handle);
      },
    );
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
    // ignore: invalid_use_of_protected_member
    isar.requireOpen();
    final cObjPtr = malloc<CObject>();

    final port = ReceivePort();
    final handle =
        IC.isar_watch_object(isar.ptr, ptr, id, port.sendPort.nativePort);
    malloc.free(cObjPtr);

    final controller = StreamController<void>(
      onCancel: () {
        IC.isar_stop_watching(handle);
      },
    );

    if (initialReturn) {
      controller.add(null);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  Query<T> buildQuery<T>({
    List<WhereClause> whereClauses = const [],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const [],
    List<DistinctProperty> distinctBy = const [],
    int? offset,
    int? limit,
    String? property,
  }) {
    // ignore: invalid_use_of_protected_member
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
