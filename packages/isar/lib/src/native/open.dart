// ignore_for_file: public_member_api_docs

import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';

import 'package:isar/src/native/bindings.dart';
import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_impl.dart';

final Pointer<Pointer<CIsarInstance>> _isarPtrPtr =
    malloc<Pointer<CIsarInstance>>();

void _initializeInstance(
  Allocator alloc,
  IsarImpl isar,
  List<CollectionSchema<dynamic>> schemas,
) {
  final maxProperties = schemas.map((e) => e.propertyIds.length).reduce(max);

  final colPtrPtr = alloc<Pointer<CIsarCollection>>();
  final offsetsPtr = alloc<Uint32>(maxProperties);

  final cols = <Type, IsarCollection<dynamic>>{};
  for (var i = 0; i < schemas.length; i++) {
    final schema = schemas[i];
    nCall(IC.isar_instance_get_collection(isar.ptr, colPtrPtr, i));

    final offsets = offsetsPtr.asTypedList(schema.propertyIds.length).toList();
    final staticSize = IC.isar_get_offsets(colPtrPtr.value, offsetsPtr);
    offsets.add(staticSize);

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

  // ignore: invalid_use_of_protected_member
  isar.attachCollections(cols);
}

Future<Isar> openIsar({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) async {
  initializeCoreBinary();
  IC.isar_connect_dart_api(NativeApi.postCObject.cast());

  return using((Arena alloc) async {
    final namePtr = name.toNativeUtf8(allocator: alloc);
    final dirPtr = directory?.toNativeUtf8(allocator: alloc) ?? nullptr;

    final schemaStr = '[${schemas.map((e) => e.schema).join(',')}]';
    final schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    final stream = wrapIsarPort(receivePort);
    IC.isar_instance_create_async(
      _isarPtrPtr,
      namePtr.cast(),
      dirPtr.cast(),
      relaxedDurability,
      schemaStrPtr.cast(),
      nativePort,
    );
    await stream.first;

    final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
    _initializeInstance(alloc, isar, schemas);
    return isar;
  });
}

Isar openIsarSync({
  required List<CollectionSchema<dynamic>> schemas,
  String? directory,
  String name = 'isar',
  bool relaxedDurability = true,
}) {
  initializeCoreBinary();
  IC.isar_connect_dart_api(NativeApi.postCObject.cast());

  return using(
    (Arena alloc) {
      final namePtr = name.toNativeUtf8(allocator: alloc);
      final dirPtr = directory?.toNativeUtf8(allocator: alloc) ?? nullptr;

      final schemaStr = '[${schemas.map((e) => e.schema).join(',')}]';
      final schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

      nCall(
        IC.isar_instance_create(
          _isarPtrPtr,
          namePtr.cast(),
          dirPtr.cast(),
          relaxedDurability,
          schemaStrPtr.cast(),
        ),
      );

      final isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
      _initializeInstance(alloc, isar, schemas);
      return isar;
    },
    malloc,
  );
}
