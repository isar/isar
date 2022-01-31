import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'isar_core.dart';
import 'isar_impl.dart';

final _isarPtrPtr = malloc<Pointer>();

void _initializeInstance(
    Allocator alloc, IsarImpl isar, List<CollectionSchema> schemas) {
  final maxProperties = schemas
      .map((e) => e.propertyIds.length)
      .reduce((value, element) => max(value, element));

  final colPtrPtr = alloc<Pointer>();
  final offsetsPtr = alloc<Uint32>(maxProperties);

  final cols = <String, IsarCollection>{};
  for (var i = 0; i < schemas.length; i++) {
    final schema = schemas[i];
    nCall(IC.isar_get_collection(isar.ptr, colPtrPtr, i));
    IC.isar_get_property_offsets(colPtrPtr.value, offsetsPtr);
    cols[schema.name] = schema.toNativeCollection(
      isar: isar,
      ptr: colPtrPtr.value,
      offsets: offsetsPtr.asTypedList(schema.propertyIds.length).toList(),
    );
  }

  // ignore: invalid_use_of_protected_member
  isar.attachCollections(cols);
}

Future<Isar> openIsarNative({
  required List<CollectionSchema> schemas,
  required String directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) async {
  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);

  return using((alloc) async {
    final namePtr = name.toNativeUtf8(allocator: alloc);
    final dirPtr = directory.toNativeUtf8(allocator: alloc);

    final schemaStr = '[' + schemas.map((e) => e.schema).join(',') + ']';
    final schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    final stream = wrapIsarPort(receivePort);
    IC.isar_create_instance_async(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
        relaxedDurability, schemaStrPtr.cast(), nativePort);
    await stream.first;

    final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
    _initializeInstance(alloc, isar, schemas);
    return isar;
  });
}

Isar openIsarNativeSync({
  required List<CollectionSchema> schemas,
  required String directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) {
  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);

  return using((alloc) {
    final namePtr = name.toNativeUtf8(allocator: alloc);
    final dirPtr = directory.toNativeUtf8(allocator: alloc);

    final schemaStr = '[' + schemas.map((e) => e.schema).join(',') + ']';
    final schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

    nCall(IC.isar_create_instance(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
        relaxedDurability, schemaStrPtr.cast()));

    final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
    _initializeInstance(alloc, isar, schemas);
    return isar;
  }, malloc);
}
