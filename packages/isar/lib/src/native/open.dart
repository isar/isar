import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import 'isar_core.dart';
import 'isar_impl.dart';

final _isarPtrPtr = malloc<Pointer>();

Isar? _openExisting(
    String name, String schemaStr, List<CollectionSchema> schemas) {
  final existingInstance = Isar.getInstance(name);
  if (existingInstance != null) {
    return existingInstance;
  }

  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);

  final namePtr = name.toNativeUtf8();
  IC.isar_get_instance(_isarPtrPtr, namePtr.cast());
  malloc.free(namePtr);

  if (_isarPtrPtr.value.address != 0) {
    final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
    _initializeInstance(isar, schemas);
    return isar;
  }
}

void _initializeInstance(IsarImpl isar, List<CollectionSchema> schemas) {
  final maxProperties = schemas
      .map((e) => e.propertyIds.length)
      .reduce((value, element) => max(value, element));
  final colPtrPtr = malloc<Pointer>();
  final offsetsPtr = malloc<Uint32>(maxProperties);

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

  malloc.free(offsetsPtr);
  malloc.free(colPtrPtr);

  // ignore: invalid_use_of_protected_member
  isar.attachCollections(cols);
}

Future<Isar> openIsarNative({
  required List<CollectionSchema> schemas,
  required String directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) async {
  final schemaStr = '[' + schemas.map((e) => e.schema).join(',') + ']';
  final existingInstance = _openExisting(name, schemaStr, schemas);
  if (existingInstance != null) {
    return existingInstance;
  }

  final path = p.join(directory, name);
  await Directory(path).create(recursive: true);

  final namePtr = name.toNativeUtf8();
  final dirPtr = directory.toNativeUtf8();
  final schemaStrPtr = schemaStr.toNativeUtf8();

  final receivePort = ReceivePort();
  final nativePort = receivePort.sendPort.nativePort;
  final stream = wrapIsarPort(receivePort);
  IC.isar_create_instance_async(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
      relaxedDurability, schemaStrPtr.cast(), nativePort);
  await stream.first;

  malloc.free(namePtr);
  malloc.free(dirPtr);
  malloc.free(schemaStrPtr);

  final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
  _initializeInstance(isar, schemas);
  return isar;
}

Isar openIsarNativeSync({
  required List<CollectionSchema> schemas,
  required String directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) {
  final schemaStr = '[' + schemas.map((e) => e.schema).join(',') + ']';
  final existingInstance = _openExisting(name, schemaStr, schemas);
  if (existingInstance != null) {
    return existingInstance;
  }

  final path = p.join(directory, name);
  Directory(path).createSync(recursive: true);

  final namePtr = name.toNativeUtf8();
  final dirPtr = directory.toNativeUtf8();
  final schemaStrPtr = schemaStr.toNativeUtf8();

  nCall(IC.isar_create_instance(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
      relaxedDurability, schemaStrPtr.cast()));

  malloc.free(namePtr);
  malloc.free(dirPtr);
  malloc.free(schemaStrPtr);

  final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
  _initializeInstance(isar, schemas);
  return isar;
}
