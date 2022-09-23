// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/index_key.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';
import 'package:isar/src/native/isar_reader_impl.dart';
import 'package:isar/src/native/isar_writer_impl.dart';
import 'package:isar/src/native/query_build.dart';
import 'package:isar/src/native/txn.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  IsarCollectionImpl({
    required this.isar,
    required this.ptr,
    required this.schema,
  });

  @override
  final IsarImpl isar;
  final Pointer<CIsarCollection> ptr;

  @override
  final CollectionSchema<OBJ> schema;

  late final _offsets = isar.offsets[OBJ]!;
  late final _staticSize = _offsets.last;

  @pragma('vm:prefer-inline')
  OBJ deserializeObject(CObject cObj) {
    final buffer = cObj.buffer.asTypedList(cObj.buffer_length);
    final reader = IsarReaderImpl(buffer);
    final object = schema.deserialize(
      cObj.id,
      reader,
      _offsets,
      isar.offsets,
    );
    schema.attach(this, cObj.id, object);
    return object;
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
      keysPtrPtr[i] = buildIndexKey(schema, schema.index(indexName), keys[i]);
    }
    return keysPtrPtr;
  }

  List<T> deserializeProperty<T>(CObjectSet objectSet, int? propertyId) {
    final values = <T>[];
    if (propertyId != null) {
      final propertyOffset = _offsets[propertyId];
      for (var i = 0; i < objectSet.length; i++) {
        final cObj = objectSet.objects.elementAt(i).ref;
        final buffer = cObj.buffer.asTypedList(cObj.buffer_length);
        values.add(
          schema.deserializeProp(
            IsarReaderImpl(buffer),
            propertyId,
            propertyOffset,
            isar.offsets,
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

  void serializeObjects(
    Txn txn,
    Pointer<CObject> objectsPtr,
    List<OBJ> objects,
  ) {
    var maxBufferSize = 0;
    for (var i = 0; i < objects.length; i++) {
      final object = objects[i];
      maxBufferSize += schema.estimateSize(object, _offsets, isar.offsets);
    }
    final bufferPtr = txn.alloc<Uint8>(maxBufferSize);
    final buffer = bufferPtr.asTypedList(maxBufferSize).buffer;

    var writtenBytes = 0;
    for (var i = 0; i < objects.length; i++) {
      final objBuffer = buffer.asUint8List(writtenBytes);
      final binaryWriter = IsarWriterImpl(objBuffer, _staticSize);

      final object = objects[i];
      schema.serialize(
        object,
        binaryWriter,
        _offsets,
        isar.offsets,
      );
      final size = binaryWriter.usedBytes;

      final cObj = objectsPtr.elementAt(i).ref;
      cObj.id = schema.getId(object);
      cObj.buffer = bufferPtr.elementAt(writtenBytes);
      cObj.buffer_length = size;

      writtenBytes += size;
    }
  }

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (Txn txn) async {
      final cObjSetPtr = txn.newCObjectSet(ids.length);
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
    return isar.getTxnSync(false, (Txn txn) {
      final cObjPtr = txn.getCObject();
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
    return isar.getTxn(false, (Txn txn) async {
      final cObjSetPtr = txn.newCObjectSet(keys.length);
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);
      IC.isar_get_all_by_index(
        ptr,
        txn.ptr,
        schema.index(indexName).id,
        keysPtrPtr,
        cObjSetPtr,
      );
      await txn.wait();
      return deserializeObjectsOrNull(cObjSetPtr.ref);
    });
  }

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<IndexKey> keys) {
    final index = schema.index(indexName);

    return isar.getTxnSync(false, (Txn txn) {
      final cObjPtr = txn.getCObject();
      final cObj = cObjPtr.ref;

      final objects = List<OBJ?>.filled(keys.length, null);
      for (var i = 0; i < keys.length; i++) {
        final keyPtr = buildIndexKey(schema, index, keys[i]);
        nCall(IC.isar_get_by_index(ptr, txn.ptr, index.id, keyPtr, cObjPtr));
        objects[i] = deserializeObjectOrNull(cObj);
      }

      return objects;
    });
  }

  @override
  int putSync(OBJ object, {bool saveLinks = true}) {
    return isar.getTxnSync(true, (Txn txn) {
      return putByIndexSyncInternal(
        txn: txn,
        object: object,
        saveLinks: saveLinks,
      );
    });
  }

  @override
  int putByIndexSync(String indexName, OBJ object, {bool saveLinks = true}) {
    return isar.getTxnSync(true, (Txn txn) {
      return putByIndexSyncInternal(
        txn: txn,
        object: object,
        indexId: schema.index(indexName).id,
        saveLinks: saveLinks,
      );
    });
  }

  int putByIndexSyncInternal({
    required Txn txn,
    int? indexId,
    required OBJ object,
    bool saveLinks = true,
  }) {
    final cObjPtr = txn.getCObject();
    final cObj = cObjPtr.ref;

    final estimatedSize = schema.estimateSize(object, _offsets, isar.offsets);
    cObj.buffer = txn.getBuffer(estimatedSize);
    final buffer = cObj.buffer.asTypedList(estimatedSize);

    final writer = IsarWriterImpl(buffer, _staticSize);
    schema.serialize(
      object,
      writer,
      _offsets,
      isar.offsets,
    );
    cObj.buffer_length = writer.usedBytes;

    cObj.id = schema.getId(object);

    if (indexId != null) {
      nCall(IC.isar_put_by_index(ptr, txn.ptr, indexId, cObjPtr));
    } else {
      nCall(IC.isar_put(ptr, txn.ptr, cObjPtr));
    }

    final id = cObj.id;
    schema.attach(this, id, object);

    if (saveLinks) {
      for (final link in schema.getLinks(object)) {
        link.saveSync();
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
    return putAllByIndexSync(null, objects, saveLinks: saveLinks);
  }

  @override
  Future<List<int>> putAllByIndex(String? indexName, List<OBJ> objects) {
    final indexId = indexName != null ? schema.index(indexName).id : null;

    return isar.getTxn(true, (Txn txn) async {
      final cObjSetPtr = txn.newCObjectSet(objects.length);
      serializeObjects(txn, cObjSetPtr.ref.objects, objects);

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
        schema.attach(this, id, object);
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
    final indexId = indexName != null ? schema.index(indexName).id : null;
    final ids = List.filled(objects.length, 0);
    isar.getTxnSync(true, (Txn txn) {
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
    return isar.getTxn(true, (Txn txn) async {
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
    return isar.getTxnSync(true, (Txn txn) {
      final deletedPtr = txn.alloc<Bool>();

      var counter = 0;
      for (var i = 0; i < ids.length; i++) {
        nCall(IC.isar_delete(ptr, txn.ptr, ids[i], deletedPtr));
        if (deletedPtr.value) {
          counter++;
        }
      }
      return counter;
    });
  }

  @override
  Future<int> deleteAllByIndex(String indexName, List<IndexKey> keys) {
    return isar.getTxn(true, (Txn txn) async {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      IC.isar_delete_all_by_index(
        ptr,
        txn.ptr,
        schema.index(indexName).id,
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
    return isar.getTxnSync(true, (Txn txn) {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      nCall(
        IC.isar_delete_all_by_index(
          ptr,
          txn.ptr,
          schema.index(indexName).id,
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
    return isar.getTxn(true, (Txn txn) async {
      IC.isar_clear(ptr, txn.ptr);
      await txn.wait();
    });
  }

  @override
  void clearSync() {
    isar.getTxnSync(true, (Txn txn) {
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
    return isar.getTxn(true, (Txn txn) async {
      final bytesPtr = txn.alloc<Uint8>(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toCString(txn.alloc);

      IC.isar_json_import(
        ptr,
        txn.ptr,
        idNamePtr,
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
    return isar.getTxnSync(true, (Txn txn) async {
      final bytesPtr = txn.getBuffer(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toCString(txn.alloc);

      nCall(
        IC.isar_json_import(
          ptr,
          txn.ptr,
          idNamePtr,
          bytesPtr,
          jsonBytes.length,
        ),
      );
    });
  }

  @override
  Future<int> count() {
    return isar.getTxn(false, (Txn txn) async {
      final countPtr = txn.alloc<Int64>();
      IC.isar_count(ptr, txn.ptr, countPtr);
      await txn.wait();
      return countPtr.value;
    });
  }

  @override
  int countSync() {
    return isar.getTxnSync(false, (Txn txn) {
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
    return isar.getTxn(false, (Txn txn) async {
      final sizePtr = txn.alloc<Int64>();
      IC.isar_get_size(ptr, txn.ptr, includeIndexes, includeLinks, sizePtr);
      await txn.wait();
      return sizePtr.value;
    });
  }

  @override
  int getSizeSync({bool includeIndexes = false, bool includeLinks = false}) {
    return isar.getTxnSync(false, (Txn txn) {
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
  Stream<void> watchLazy({bool fireImmediately = false}) {
    isar.requireOpen();
    final port = ReceivePort();
    final handle =
        IC.isar_watch_collection(isar.ptr, ptr, port.sendPort.nativePort);
    final controller = StreamController<void>(
      onCancel: () {
        IC.isar_stop_watching(handle);
        port.close();
      },
    );

    if (fireImmediately) {
      controller.add(null);
    }

    controller.addStream(port);
    return controller.stream;
  }

  @override
  Stream<OBJ?> watchObject(Id id, {bool fireImmediately = false}) {
    return watchObjectLazy(id, fireImmediately: fireImmediately)
        .asyncMap((event) => get(id));
  }

  @override
  Stream<void> watchObjectLazy(Id id, {bool fireImmediately = false}) {
    isar.requireOpen();
    final cObjPtr = malloc<CObject>();

    final port = ReceivePort();
    final handle =
        IC.isar_watch_object(isar.ptr, ptr, id, port.sendPort.nativePort);
    malloc.free(cObjPtr);

    final controller = StreamController<void>(
      onCancel: () {
        IC.isar_stop_watching(handle);
        port.close();
      },
    );

    if (fireImmediately) {
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

  @override
  Future<void> verify(List<OBJ> objects) async {
    await isar.verify();
    return isar.getTxn(false, (Txn txn) async {
      final cObjSetPtr = txn.newCObjectSet(objects.length);
      serializeObjects(txn, cObjSetPtr.ref.objects, objects);

      IC.isar_verify(ptr, txn.ptr, cObjSetPtr);
      await txn.wait();
    });
  }

  @override
  Future<void> verifyLink(
    String linkName,
    List<int> sourceIds,
    List<int> targetIds,
  ) async {
    final link = schema.link(linkName);

    return isar.getTxn(false, (Txn txn) async {
      final idsPtr = txn.alloc<Int64>(sourceIds.length + targetIds.length);
      for (var i = 0; i < sourceIds.length; i++) {
        idsPtr[i * 2] = sourceIds[i];
        idsPtr[i * 2 + 1] = targetIds[i];
      }

      IC.isar_link_verify(
        ptr,
        txn.ptr,
        link.id,
        idsPtr,
        sourceIds.length + targetIds.length,
      );
      await txn.wait();
    });
  }
}
