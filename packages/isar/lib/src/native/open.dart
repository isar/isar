part of isar_native;

Future<Isar> openIsarInternal({
  String name = 'isar',
  required String directory,
  required String schema,
  required Map<String, IsarCollection> Function(IsarImpl) getCollections,
  int maxSize = 1000000000,
  Uint8List? encryptionKey,
}) async {
  assert(name.isNotEmpty);
  final existingInstance = Isar.getInstance(name);
  if (existingInstance != null) {
    return existingInstance;
  }
  await Directory(p.join(directory, name)).create(recursive: true);
  initializeIsarCore();
  IC.isar_connect_dart_api(NativeApi.postCObject);

  final isarPtrPtr = malloc<Pointer>();
  final namePtr = name.toNativeUtf8();
  final pathPtr = directory.toNativeUtf8();
  IC.isar_get_instance(isarPtrPtr, namePtr.cast());
  if (isarPtrPtr.value.address == 0) {
    final schemaPtr = schema.toNativeUtf8();
    var encKeyPtr = Pointer<Uint8>.fromAddress(0);
    if (encryptionKey != null) {
      assert(encryptionKey.length == 32,
          'Encryption keys need to contain 32 byte (256bit).');
      encKeyPtr = malloc(32);
      encKeyPtr.asTypedList(32).setAll(0, encryptionKey);
    }
    final receivePort = ReceivePort();
    final nativePort = receivePort.sendPort.nativePort;
    final stream = wrapIsarPort(receivePort);
    IC.isar_create_instance(isarPtrPtr, namePtr.cast(), pathPtr.cast(), maxSize,
        schemaPtr.cast(), encKeyPtr, nativePort);
    await stream.first;
    malloc.free(schemaPtr);
    if (encryptionKey != null) {
      malloc.free(encKeyPtr);
    }
  }
  malloc.free(namePtr);
  malloc.free(pathPtr);

  final isarPtr = isarPtrPtr.value;
  malloc.free(isarPtrPtr);

  final isar = IsarImpl(name, schema, isarPtr);
  final collections = getCollections(isar);
  //ignore: invalid_use_of_protected_member
  isar.attachCollections(collections);
  return isar;
}
