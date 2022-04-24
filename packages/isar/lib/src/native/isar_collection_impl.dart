import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/native/isar_core.dart';

import 'binary_reader.dart';
import 'bindings.dart';
import 'index_key.dart';
import 'isar_impl.dart';
import 'query_build.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;
  final Pointer ptr;

  final CollectionSchema<OBJ> schema;
  final int _staticSize;
  final List<int> _offsets;

  IsarCollectionImpl({
    required this.isar,
    required this.ptr,
    required this.schema,
    required int staticSize,
    required List<int> offsets,
  })  : _staticSize = staticSize,
        _offsets = offsets;

  @override
  String get name => schema.name;

  @pragma('vm:prefer-inline')
  OBJ deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return schema.deserializeNative(this, rawObj.id, reader, _offsets);
  }

  @pragma('vm:prefer-inline')
  OBJ? deserializeObjectOrNull(RawObject rawObj) {
    if (!rawObj.buffer.isNull) {
      return deserializeObject(rawObj);
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  List<OBJ> deserializeObjects(RawObjectSet objectSet) {
    final objects = <OBJ>[];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObjPtr = objectSet.objects.elementAt(i);
      final object = deserializeObject(rawObjPtr.ref);
      objects.add(object);
    }
    return objects;
  }

  @pragma('vm:prefer-inline')
  List<OBJ?> deserializeObjectsOrNull(RawObjectSet objectSet) {
    final objects = List<OBJ?>.filled(objectSet.length, null);
    for (var i = 0; i < objectSet.length; i++) {
      final rawObj = objectSet.objects.elementAt(i).ref;
      if (!rawObj.buffer.isNull) {
        objects[i] = deserializeObject(rawObj);
      }
    }
    return objects;
  }

  @pragma('vm:prefer-inline')
  Pointer<Pointer<NativeType>> _getKeysPtr(
      String indexName, List<List<Object?>> values, Allocator alloc) {
    final keysPtrPtr = alloc<Pointer>(values.length);
    for (var i = 0; i < values.length; i++) {
      keysPtrPtr[i] = buildIndexKey(schema, indexName, values[i]);
    }
    return keysPtrPtr;
  }

  List<T> deserializeProperty<T>(RawObjectSet objectSet, int propertyIndex) {
    final values = <T>[];
    final propertyOffset = _offsets[propertyIndex];
    for (var i = 0; i < objectSet.length; i++) {
      final rawObj = objectSet.objects.elementAt(i).ref;
      final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
      values.add(schema.deserializePropNative(
        rawObj.id,
        BinaryReader(buffer),
        propertyIndex,
        propertyOffset,
      ));
    }
    return values;
  }

  @override
  Future<OBJ?> get(int id) => getAll([id]).then((objects) => objects[0]);

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txn) async {
      final rawObjSetPtr = txn.allocRawObjSet(ids.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      for (var i = 0; i < ids.length; i++) {
        objectsPtr.elementAt(i).ref.id = ids[i];
      }
      IC.isar_get_all(ptr, txn.ptr, rawObjSetPtr);
      await txn.wait();
      return deserializeObjectsOrNull(rawObjSetPtr.ref);
    });
  }

  @override
  OBJ? getSync(int id) => getAllSync([id])[0];

  @override
  List<OBJ?> getAllSync(List<int> ids) {
    return isar.getTxnSync(false, (txn) {
      final rawObjPtr = txn.allocRawObject();
      final rawObj = rawObjPtr.ref;

      final objects = List<OBJ?>.filled(ids.length, null);
      for (var i = 0; i < ids.length; i++) {
        rawObj.id = ids[i];
        nCall(IC.isar_get(ptr, txn.ptr, rawObjPtr));
        objects[i] = deserializeObjectOrNull(rawObj);
      }

      return objects;
    });
  }

  @override
  Future<OBJ?> getByIndex(
    String indexName,
    List<Object?> key,
  ) =>
      getAllByIndex(indexName, [key]).then((objects) => objects[0]);

  @override
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(false, (txn) async {
      final rawObjSetPtr = txn.allocRawObjSet(keys.length);
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);
      IC.isar_get_all_by_index(ptr, txn.ptr, schema.indexIdOrErr(indexName),
          keysPtrPtr, rawObjSetPtr);
      await txn.wait();
      return deserializeObjectsOrNull(rawObjSetPtr.ref);
    });
  }

  @override
  OBJ? getByIndexSync(
    String indexName,
    List<Object?> key,
  ) =>
      getAllByIndexSync(indexName, [key])[0];

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List<List<Object?>> keys) {
    return isar.getTxnSync(false, (txn) {
      final rawObjPtr = txn.allocRawObject();
      final rawObj = rawObjPtr.ref;
      final indexId = schema.indexIdOrErr(indexName);

      final objects = List<OBJ?>.filled(keys.length, null);
      for (var i = 0; i < keys.length; i++) {
        final keyPtr = buildIndexKey(schema, indexName, keys[i]);
        nCall(IC.isar_get_by_index(ptr, txn.ptr, indexId, keyPtr, rawObjPtr));
        objects[i] = deserializeObjectOrNull(rawObj);
      }

      return objects;
    });
  }

  @override
  Future<int> put(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return putAll(
      [object],
      replaceOnConflict: replaceOnConflict,
      saveLinks: saveLinks,
    ).then((ids) => ids[0]);
  }

  @override
  Future<List<int>> putAll(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return isar.getTxn(true, (txn) async {
      final rawObjSetPtr = txn.allocRawObjSet(objects.length);
      final objectsPtr = rawObjSetPtr.ref.objects;

      Pointer<Uint8> allocBuf(int size) => txn.alloc<Uint8>(size);
      for (var i = 0; i < objects.length; i++) {
        final object = objects[i];
        final rawObj = objectsPtr.elementAt(i).ref;
        schema.serializeNative(
            this, rawObj, object, _staticSize, _offsets, allocBuf);
        rawObj.id = schema.getId(object) ?? Isar.autoIncrement;
      }
      IC.isar_put_all(ptr, txn.ptr, rawObjSetPtr, replaceOnConflict);

      await txn.wait();
      final rawObjectSet = rawObjSetPtr.ref;
      final ids = List<int>.filled(objects.length, 0);
      final linkFutures = <Future>[];
      for (var i = 0; i < objects.length; i++) {
        final rawObjPtr = rawObjectSet.objects.elementAt(i);
        final id = rawObjPtr.ref.id;
        ids[i] = id;

        final object = objects[i];
        schema.setId?.call(object, id);

        if (schema.hasLinks) {
          schema.attachLinks(this, id, object);
          if (saveLinks) {
            for (var link in schema.getLinks(object)) {
              if (link.isChanged) {
                linkFutures.add(link.save());
              }
            }
          }
        }
      }
      if (linkFutures.isNotEmpty) {
        await Future.wait(linkFutures);
      }
      return ids;
    });
  }

  @override
  int putSync(
    OBJ object, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return putAllSync(
      [object],
      replaceOnConflict: replaceOnConflict,
      saveLinks: saveLinks,
    )[0];
  }

  @override
  List<int> putAllSync(
    List<OBJ> objects, {
    bool replaceOnConflict = false,
    bool saveLinks = false,
  }) {
    return isar.getTxnSync(true, (txn) {
      final rawObjPtr = txn.allocRawObject();
      final rawObj = rawObjPtr.ref;

      final ids = List<int>.filled(objects.length, 0);
      for (var i = 0; i < objects.length; i++) {
        final object = objects[i];
        schema.serializeNative(
            this, rawObj, object, _staticSize, _offsets, txn.allocBuffer);
        rawObj.id = schema.getId(object) ?? Isar.autoIncrement;
        nCall(IC.isar_put(ptr, txn.ptr, rawObjPtr, replaceOnConflict));

        final id = rawObj.id;
        ids[i] = id;
        schema.setId?.call(object, id);

        if (schema.hasLinks) {
          schema.attachLinks(this, id, object);
          if (saveLinks) {
            for (var link in schema.getLinks(object)) {
              if (link.isChanged) {
                link.saveSync();
              }
            }
          }
        }
      }
      return ids;
    });
  }

  @override
  Future<bool> delete(int id) => deleteAll([id]).then((count) => count == 1);

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
  bool deleteSync(int id) => deleteAllSync([id]) == 1;

  @override
  int deleteAllSync(List<int> ids) {
    return isar.getTxnSync(true, (txn) {
      final deletedPtr = txn.allocBuffer(1);

      var counter = 0;
      for (var id in ids) {
        nCall(IC.isar_delete(ptr, txn.ptr, id, deletedPtr));
        if (deletedPtr.value == 1) {
          counter++;
        }
      }
      return counter;
    });
  }

  @override
  Future<bool> deleteByIndex(String indexName, List<Object?> key) =>
      deleteAllByIndex(indexName, [key]).then((count) => count == 1);

  @override
  Future<int> deleteAllByIndex(String indexName, List<List<Object?>> keys) {
    return isar.getTxn(true, (txn) async {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      IC.isar_delete_all_by_index(ptr, txn.ptr, schema.indexIdOrErr(indexName),
          keysPtrPtr, keys.length, countPtr);
      await txn.wait();

      return countPtr.value;
    });
  }

  @override
  bool deleteByIndexSync(String indexName, List<Object?> key) =>
      deleteAllByIndexSync(indexName, [key]) == 1;

  @override
  int deleteAllByIndexSync(String indexName, List<List<Object?>> keys) {
    return isar.getTxnSync(true, (txn) {
      final countPtr = txn.alloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, keys, txn.alloc);

      nCall(IC.isar_delete_all_by_index(ptr, txn.ptr,
          schema.indexIdOrErr(indexName), keysPtrPtr, keys.length, countPtr));
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
  Future<void> importJson(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    final bytes = Utf8Encoder().convert(jsonEncode(json));
    return importJsonRaw(bytes, replaceOnConflict: replaceOnConflict);
  }

  @override
  Future<void> importJsonRaw(Uint8List jsonBytes,
      {bool replaceOnConflict = false}) {
    return isar.getTxn(true, (txn) async {
      final bytesPtr = txn.alloc<Uint8>(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toNativeUtf8(allocator: txn.alloc);

      IC.isar_json_import(ptr, txn.ptr, idNamePtr.cast(), bytesPtr,
          jsonBytes.length, replaceOnConflict);
      await txn.wait();
    });
  }

  @override
  void importJsonSync(List<Map<String, dynamic>> json,
      {bool replaceOnConflict = false}) {
    final bytes = Utf8Encoder().convert(jsonEncode(json));
    importJsonRawSync(bytes, replaceOnConflict: replaceOnConflict);
  }

  @override
  void importJsonRawSync(Uint8List jsonBytes,
      {bool replaceOnConflict = false}) {
    return isar.getTxnSync(true, (txn) async {
      final bytesPtr = txn.allocBuffer(jsonBytes.length);
      bytesPtr.asTypedList(jsonBytes.length).setAll(0, jsonBytes);
      final idNamePtr = schema.idName.toNativeUtf8(allocator: txn.alloc);

      nCall(IC.isar_json_import(ptr, txn.ptr, idNamePtr.cast(), bytesPtr,
          jsonBytes.length, replaceOnConflict));
    });
  }

  @override
  Stream<void> watchLazy() {
    // ignore: invalid_use_of_protected_member
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
    // ignore: invalid_use_of_protected_member
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
