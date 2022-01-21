import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;

import 'isar_core.dart';
import 'isar_impl.dart';

Future<Isar> openIsarNative({
  required List<CollectionSchema> schemas,
  required String directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) async {
  assert(name.isNotEmpty);
  final existingInstance = Isar.getInstance(name);
  if (existingInstance != null) {
    return existingInstance;
  }

  final path = p.join(directory, name);
  await Directory(path).create(recursive: true);
  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);

  final schema = '[' + schemas.map((e) => e.schema).join(',') + ']';

  final isarPtrPtr = malloc<Pointer>();
  final pathPtr = path.toNativeUtf8();
  IC.isar_get_instance(isarPtrPtr, pathPtr.cast());
  if (isarPtrPtr.value.address == 0) {
    final schemaPtr = schema.toNativeUtf8();
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    final stream = wrapIsarPort(receivePort);
    IC.isar_create_instance(isarPtrPtr, pathPtr.cast(), relaxedDurability,
        schemaPtr.cast(), nativePort);
    await stream.first;
    malloc.free(schemaPtr);
  }
  malloc.free(pathPtr);

  final isarPtr = isarPtrPtr.value;
  malloc.free(isarPtrPtr);

  final isar = IsarImpl(name, schema, isarPtr);

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
  return isar;
}
