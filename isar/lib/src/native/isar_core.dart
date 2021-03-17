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
final minDate = DateTime.fromMillisecondsSinceEpoch(minLong);
final maxDate = DateTime.fromMillisecondsSinceEpoch(maxLong);

const nullInt = minInt;
const nullLong = minLong;
const nullFloat = minFloat;
const nullDouble = minDouble;
final nullDate = minDate;

class IsarCoreUtils {
  static final syncTxnPtr = malloc<Pointer>();
  static final syncRawObjPtr = malloc<RawObject>();
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
  } else if (Platform.isMacOS) {
    dylib = dylibs['macos'] ?? 'libisar.dylib';
  } else if (Platform.isWindows) {
    dylib = dylibs['windows'] ?? 'libisar.dll';
  } else if (Platform.isLinux) {
    dylib = dylibs['linux'] ?? 'libisar.so';
  }
  try {
    if (Platform.isIOS) {
      _IC = IsarCoreBindings(DynamicLibrary.process());
    } else {
      _IC ??= IsarCoreBindings(DynamicLibrary.open(dylib));
    }
  } catch (e) {
    print(e);
    throw IsarError(
        'Could not initialize IsarCore library. If you create a Flutter app, '
        'make sure to add isar_flutter_libs to your dependencies. Isar does not '
        'support 32-bit processors so make sure that your device / emulator '
        'has a 64-bit processor.');
  }
}

extension RawObjectX on RawObject {
  void freeData() {
    if (buffer.address != 0) {
      malloc.free(buffer);
    }
  }
}

extension PointerX on Pointer {
  bool get isNull => address == 0;
}
