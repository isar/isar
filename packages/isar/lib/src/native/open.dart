// ignore_for_file: public_member_api_docs, invalid_use_of_protected_member

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/common/schemas.dart';
import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';

final Pointer<Pointer<CIsarInstance>> _isarPtrPtr =
    malloc<Pointer<CIsarInstance>>();

List<int> _getOffsets(
  Pointer<CIsarCollection> colPtr,
  int propertiesCount,
  int embeddedColId,
) {
  final offsetsPtr = malloc<Uint32>(propertiesCount);
  final staticSize = IC.isar_get_offsets(colPtr, embeddedColId, offsetsPtr);
  final offsets = offsetsPtr.asTypedList(propertiesCount).toList();
  offsets.add(staticSize);
  malloc.free(offsetsPtr);
  return offsets;
}

void _initializeInstance(
  IsarImpl isar,
  List<CollectionSchema<dynamic>> schemas,
) {
  final colPtrPtr = malloc<Pointer<CIsarCollection>>();

  final cols = <Type, IsarCollection<dynamic>>{};
  for (final schema in schemas) {
    nCall(IC.isar_instance_get_collection(isar.ptr, colPtrPtr, schema.id));

    final offsets = _getOffsets(colPtrPtr.value, schema.properties.length, 0);

    for (final embeddedSchema in schema.embeddedSchemas.values) {
      final embeddedType = embeddedSchema.type;
      if (!isar.offsets.containsKey(embeddedType)) {
        final offsets = _getOffsets(
          colPtrPtr.value,
          embeddedSchema.properties.length,
          embeddedSchema.id,
        );
        isar.offsets[embeddedType] = offsets;
      }
    }

    schema.toCollection(<OBJ>() {
      isar.offsets[OBJ] = offsets;

      schema as CollectionSchema<OBJ>;
      cols[OBJ] = IsarCollectionImpl<OBJ>(
        isar: isar,
        ptr: colPtrPtr.value,
        schema: schema,
      );
    });
  }

  malloc.free(colPtrPtr);

  isar.attachCollections(cols);
}

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  required String directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) async {
  initializeCoreBinary();
  IC.isar_connect_dart_api(NativeApi.postCObject.cast());

  return using((Arena alloc) async {
    final namePtr = name.toCString(alloc);
    final dirPtr = directory.toCString(alloc);

    final schemasJson = getSchemas(schemas).map((e) => e.toJson());
    final schemaStrPtr = jsonEncode(schemasJson.toList()).toCString(alloc);

    final compactMinFileSize = compactOnLaunch?.minFileSize;
    final compactMinBytes = compactOnLaunch?.minBytes;
    final compactMinRatio =
        compactOnLaunch == null ? double.nan : compactOnLaunch.minRatio;

    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    final stream = wrapIsarPort(receivePort);
    IC.isar_instance_create_async(
      _isarPtrPtr,
      namePtr,
      dirPtr,
      schemaStrPtr,
      maxSizeMiB,
      relaxedDurability,
      compactMinFileSize ?? 0,
      compactMinBytes ?? 0,
      compactMinRatio ?? 0,
      nativePort,
    );
    await stream.first;

    final isar = IsarImpl(name, _isarPtrPtr.value);
    _initializeInstance(isar, schemas);
    return isar;
  });
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  required String directory,
  required String name,
  required int maxSizeMiB,
  required bool relaxedDurability,
  CompactCondition? compactOnLaunch,
}) {
  initializeCoreBinary();
  IC.isar_connect_dart_api(NativeApi.postCObject.cast());
  return using((Arena alloc) {
    final namePtr = name.toCString(alloc);
    final dirPtr = directory.toCString(alloc);

    final schemasJson = getSchemas(schemas).map((e) => e.toJson());
    final schemaStrPtr = jsonEncode(schemasJson.toList()).toCString(alloc);

    final compactMinFileSize = compactOnLaunch?.minFileSize;
    final compactMinBytes = compactOnLaunch?.minBytes;
    final compactMinRatio =
        compactOnLaunch == null ? double.nan : compactOnLaunch.minRatio;

    nCall(
      IC.isar_instance_create(
        _isarPtrPtr,
        namePtr,
        dirPtr,
        schemaStrPtr,
        maxSizeMiB,
        relaxedDurability,
        compactMinFileSize ?? 0,
        compactMinBytes ?? 0,
        compactMinRatio ?? 0,
      ),
    );

    final isar = IsarImpl(name, _isarPtrPtr.value);
    _initializeInstance(isar, schemas);
    return isar;
  });
}
