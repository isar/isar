part of isar_native;

const minBool = nullBool;
const maxBool = trueBool;
const minInt = -2147483648;
const maxInt = 2147483647;
const minLong = -9223372036854775808;
const maxLong = 9223372036854775807;
const minFloat = -3.40282347e+38;
const maxFloat = 3.40282347e+38;
const minDouble = -1.7976931348623157e+308;
const maxDouble = 1.7976931348623157e+308;

const nullInt = minInt;
const nullFloat = double.nan;
const nullLong = minLong;
const nullDouble = double.nan;
const nullBool = 0;
const falseBool = 1;
const trueBool = 2;

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
    throw IsarError(
        'Could not initialize IsarCore library. If you create a Flutter app, '
        'make sure to add isar_flutter to your dependencies.');
  }
}

extension RawObjectX on RawObject {
  ObjectId? get oid {
    if (oid_time != 0) {
      return ObjectIdImpl(oid_time, oid_rand_counter);
    } else {
      return null;
    }
  }

  set oid(ObjectId? oid) {
    if (oid != null) {
      final oidImpl = oid as ObjectIdImpl;
      oid_time = oidImpl.time;
      oid_rand_counter = oidImpl.randCounter;
    } else {
      oid_time = 0;
      oid_rand_counter = 0;
    }
  }
}
