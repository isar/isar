import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import '../../isar.dart';

import 'bindings.dart';
import 'isar_collection_impl.dart';
import 'isar_core.dart';
import 'isar_impl.dart';

final Pointer<Pointer<CIsarInstance>> _isarPtrPtr = malloc<Pointer<CIsarInstance>>();

void _initializeInstance(
    Allocator alloc, IsarImpl isar, List<CollectionSchema<dynamic>> schemas) {
  final int maxProperties = schemas
      .map((CollectionSchema e) => e.propertyIds.length)
      .reduce((int value, int element) => max(value, element));

  final Pointer<Pointer<CIsarCollection>> colPtrPtr = alloc<Pointer<CIsarCollection>>();
  final Pointer<Uint32> offsetsPtr = alloc<Uint32>(maxProperties);

  final Map<Type, IsarCollection> cols = <Type, IsarCollection<dynamic>>{};
  for (int i = 0; i < schemas.length; i++) {
    final CollectionSchema schema = schemas[i];
    nCall(IC.isar_get_collection(isar.ptr, colPtrPtr, i));
    final int staticSize =
        IC.isar_get_static_size_and_offsets(colPtrPtr.value, offsetsPtr);
    final List<int> offsets = offsetsPtr.asTypedList(schema.propertyIds.length).toList();
    schema.toCollection(<OBJ>() {
      schema as CollectionSchema<OBJ>;
      cols[OBJ] = IsarCollectionImpl<OBJ>(
        isar: isar,
        ptr: colPtrPtr.value,
        schema: schema,
        staticSize: staticSize,
        offsets: offsets,
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
    final Pointer<Utf8> namePtr = name.toNativeUtf8(allocator: alloc);
    final Pointer<Utf8> dirPtr = directory?.toNativeUtf8(allocator: alloc) ?? nullptr;

    final String schemaStr = '[${schemas.map((CollectionSchema e) => e.schema).join(',')}]';
    final Pointer<Utf8> schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

    final ReceivePort receivePort = ReceivePort();
    final int nativePort = receivePort.sendPort.nativePort;
    final Stream<void> stream = wrapIsarPort(receivePort);
    IC.isar_create_instance_async(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
        relaxedDurability, schemaStrPtr.cast(), nativePort);
    await stream.first;

    final IsarImpl isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
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

  return using((Arena alloc) {
    final Pointer<Utf8> namePtr = name.toNativeUtf8(allocator: alloc);
    final Pointer<Utf8> dirPtr = directory?.toNativeUtf8(allocator: alloc) ?? nullptr;

    final String schemaStr = '[${schemas.map((CollectionSchema e) => e.schema).join(',')}]';
    final Pointer<Utf8> schemaStrPtr = schemaStr.toNativeUtf8(allocator: alloc);

    nCall(IC.isar_create_instance(_isarPtrPtr, namePtr.cast(), dirPtr.cast(),
        relaxedDurability, schemaStrPtr.cast()));

    final IsarImpl isar = IsarImpl(name, schemaStr, _isarPtrPtr.value);
    _initializeInstance(alloc, isar, schemas);
    return isar;
  }, malloc);
}
