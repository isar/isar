part of isar_native;

const nullBool = 0;
const falseBool = 1;
const trueBool = 2;

const minBool = nullBool;
const maxBool = trueBool;
const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minFloat = double.nan;
const maxFloat = double.infinity;
const minDouble = double.nan;
const maxDouble = double.infinity;

const nullInt = minInt;
const nullLong = minLong;
const nullFloat = minFloat;
const nullDouble = minDouble;

class IsarCoreUtils {
  static final syncTxnPtr = allocate<Pointer>();
  static final syncRawObjPtr = allocate<RawObject>();
}

IsarCoreBindings? _IC;
IsarCoreBindings get IC => _IC!;

void initializeIsarCore({Map<String, String> dylibs = const {}}) {
  if (_IC != null) {
    return;
  }
  late String dylib;
  if (Platform.isAndroid) {
    dylib = dylibs['android'] ?? 'libisar.so';
  } else if (Platform.isIOS) {
    dylib = dylibs['ios'] ?? 'libisar.dylib';
  } else if (Platform.isMacOS) {
    dylib = dylibs['macos'] ?? 'libisar.dylib';
  } else if (Platform.isWindows) {
    dylib = dylibs['windows'] ?? 'libisar.dll';
  } else if (Platform.isLinux) {
    dylib = dylibs['linux'] ?? 'libisar.so';
  }
  try {
    _IC ??= IsarCoreBindings(DynamicLibrary.open(dylib));
  } catch (e) {
    print(e);
    throw IsarError(
        'Could not initialize IsarCore library. If you create a Flutter app, '
        'make sure to add isar_flutter to your dependencies. Isar does not '
        'support 32-bit processors so make sure that your device / emulator '
        'has a 64-bit processor.');
  }
}

const _encoder = Utf8Encoder();
const _decoder = Utf8Decoder();

extension RawObjectX on RawObject {
  dynamic? get id {
    if (oid_str_length > 0) {
      if (oid_num != 0) {
        return null;
      } else {
        return _decoder.convert(oid_str.asTypedList(oid_str_length));
      }
    } else {
      return oid_num;
    }
  }

  set id(dynamic? id) {
    if (id != null) {
      if (id is String) {
        final bytes = _encoder.convert(id);
        final ptr = allocate<Uint8>(count: bytes.length);
        final ptrBytes = ptr.asTypedList(bytes.length);
        ptrBytes.setAll(0, bytes);
        oid_str = ptr;
        oid_str_length = bytes.length;
        oid_num = 0;
      } else if (id is int) {
        oid_num = id;
        oid_str = Pointer.fromAddress(0);
        oid_str_length = 0;
      } else {
        throw UnimplementedError();
      }
    } else {
      oid_num = 0;
      oid_str_length = 0;
      oid_str = Pointer.fromAddress(0);
    }
  }

  void freeId() {
    if (oid_str.address != 0) {
      free(oid_str);
    }
  }

  void freeData() {
    if (buffer.address != 0) {
      free(buffer);
    }
  }
}

extension PointerX on Pointer {
  bool get isNull => address == 0;
}
