import 'dart:async';
import 'dart:isolate';

import 'package:isar/isar.dart';
import 'package:isar/src/native/isar_core.dart';

import 'bindings.dart';
import 'index_key.dart';
import 'util/native_call.dart';
import 'isar_impl.dart';
import 'native_query_builder.dart';

class IsarCollectionImpl<OBJ> extends IsarCollection<OBJ> {
  @override
  final IsarImpl isar;

  final IsarTypeAdapter<OBJ> adapter;
  final Pointer ptr;

  final String idName;
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
    required this.idName,
    required this.propertyOffsets,
    required this.propertyIds,
    required this.indexIds,
    required this.indexTypes,
    required this.linkIds,
    required this.backlinkIds,
    required this.getId,
  });

  int indexIdOrErr(String indexName) {
    final indexId = indexIds[indexName];
    if (indexId != null) {
      return indexId;
    } else {
      throw IsarError('Unknown index "$indexName"');
    }
  }

  OBJ deserializeObject(RawObject rawObj) {
    final buffer = rawObj.buffer.asTypedList(rawObj.buffer_length);
    final reader = BinaryReader(buffer);
    return adapter.deserialize(this, rawObj.id, reader, propertyOffsets);
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
      String indexName, List<List<dynamic>> values) {
    final keysPtrPtr = malloc<Pointer>(values.length);
    for (var i = 0; i < values.length; i++) {
      keysPtrPtr[i] = buildIndexKey(this, indexName, values[i]);
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
        rawObj.id,
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

  @override
  Future<List<OBJ?>> getAll(List<int> ids) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(ids.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      for (var i = 0; i < ids.length; i++) {
        objectsPtr.elementAt(i).ref.id = ids[i];
      }
      IC.isar_get_all(ptr, txnPtr, rawObjSetPtr);
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
  Future<List<OBJ?>> getAllByIndex(String indexName, List<List> values) {
    return isar.getTxn(false, (txnPtr, stream) async {
      final rawObjSetPtr = allocRawObjSet(values.length);
      final objectsPtr = rawObjSetPtr.ref.objects;
      final keysPtrPtr = _getKeysPtr(indexName, values);
      IC.isar_get_all_by_index(
          ptr, txnPtr, indexIdOrErr(indexName), keysPtrPtr, rawObjSetPtr);
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
  List<OBJ?> getAllSync(List<int> ids) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      final rawObj = rawObjPtr.ref;

      try {
        final objects = <OBJ?>[];
        for (var id in ids) {
          rawObj.id = id;
          nCall(IC.isar_get(ptr, txnPtr, rawObjPtr));
          objects.add(deserializeObjectOrNull(rawObj));
        }

        return objects;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
  }

  @override
  List<OBJ?> getAllByIndexSync(String indexName, List values) {
    return isar.getTxnSync(false, (txnPtr) {
      final rawObjPtr = malloc<RawObject>();
      final rawObj = rawObjPtr.ref;
      final indexId = indexIdOrErr(indexName);

      try {
        final objects = <OBJ?>[];
        for (var value in values) {
          final keyPtr = buildIndexKey(this, indexName, value);
          nCall(IC.isar_get_by_index(ptr, txnPtr, indexId, keyPtr, rawObjPtr));
          objects.add(deserializeObjectOrNull(rawObj));
        }

        return objects;
      } finally {
        malloc.free(rawObjPtr);
      }
    });
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
  Future<int> deleteAllByIndex(String indexName, List<List> values) {
    return isar.getTxn(true, (txnPtr, stream) async {
      final countPtr = malloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, values);
      IC.isar_delete_all_by_index(ptr, txnPtr, indexIdOrErr(indexName),
          keysPtrPtr, values.length, countPtr);
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
  int deleteAllByIndexSync(String indexName, List<List> values) {
    return isar.getTxnSync(true, (txnPtr) {
      final countPtr = malloc<Uint32>();
      final keysPtrPtr = _getKeysPtr(indexName, values);
      try {
        nCall(IC.isar_delete_all_by_index(ptr, txnPtr, indexIdOrErr(indexName),
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
      final idNamePtr = idName.toNativeUtf8();
      IC.isar_json_import(
          ptr, txnPtr, idNamePtr.cast(), bytesPtr, jsonBytes.length);

      try {
        await stream.first;
      } finally {
        malloc.free(bytesPtr);
        malloc.free(idNamePtr);
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
    Sort whereSort = Sort.asc,
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
