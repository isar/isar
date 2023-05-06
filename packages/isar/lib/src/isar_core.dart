part of isar;

late final _IsarCore IsarCore;
var _isarCoreInitialized = false;

class _IsarCore extends IsarCoreBindings {
  _IsarCore(super.dynamicLibrary);

  Pointer<Pointer<NativeType>> ptrPtr = malloc<Pointer>();
  Pointer<Uint32> countPtr = malloc<Uint32>();

  Pointer<Uint16> _nativeStringPtr = nullptr;
  int _nativeStringPtrLength = 0;

  late final Pointer<Pointer<Uint16>> stringPtrPtr = ptrPtr.cast();
  Pointer<Uint16> get stringPtr => stringPtrPtr.value;

  late final Pointer<Pointer<CIsarReader>> readerPtrPtr = ptrPtr.cast();
  Pointer<CIsarReader> get readerPtr => readerPtrPtr.value;

  Pointer<CString> toNativeString(String? str) {
    if (str == null) {
      return nullptr;
    }

    if (_nativeStringPtrLength < str.length) {
      if (_nativeStringPtr != nullptr) {
        malloc.free(_nativeStringPtr);
      }
      _nativeStringPtr = malloc<Uint16>(str.length);
      _nativeStringPtrLength = str.length;
    }

    for (var i = 0; i < str.length; i++) {
      _nativeStringPtr[i] = str.codeUnitAt(i);
    }

    return IsarCore.isar_string(_nativeStringPtr, str.length);
  }

  String? fromNativeString(Pointer<Uint16> ptr, int length) {
    if (ptr == nullptr) {
      return null;
    }

    return String.fromCharCodes(ptr.asTypedList(length));
  }
}

void _initializeIsarCore({Map<Abi, String> libraries = const {}}) {
  if (_isarCoreInitialized) {
    return;
  }

  String? libraryPath;
  if (!Platform.isIOS) {
    libraryPath = libraries[Abi.current()] ?? Abi.current().localName;
  }

  try {
    late DynamicLibrary dylib;
    if (Platform.isIOS) {
      dylib = DynamicLibrary.process();
    } else {
      dylib = DynamicLibrary.open(libraryPath!);
    }
    IsarCore = _IsarCore(dylib);
  } catch (e) {
    throw IsarError(
      'Could not initialize IsarCore library for processor architecture '
      '"${Abi.current()}". If you create a Flutter app, make sure to add '
      'isar_flutter_libs to your dependencies.\n$e',
    );
  }

  final coreVersion = IsarCore.isar_version().cast<Utf8>().toDartString();
  if (coreVersion != Isar.version && coreVersion != 'debug') {
    throw IsarError(
      'Incorrect Isar Core version: Required ${Isar.version} found '
      '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
      'have a Dart only project, make sure that old Isar Core binaries are '
      'deleted.',
    );
  }

  _isarCoreInitialized = true;
}

extension _NativeError on int {
  void checkNoError() {
    if (this != 0) {
      final length = IsarCore.isar_get_error(this, IsarCore.stringPtrPtr);
      final error = IsarCore.fromNativeString(IsarCore.stringPtr, length);
      if (error != null) {
        throw IsarError(error);
      } else {
        throw IsarError(
          'There was an error but it could not be loaded from IsarCore.',
        );
      }
    }
  }
}

extension PointerX on Pointer {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}

extension on Abi {
  String get localName {
    switch (Abi.current()) {
      case Abi.androidArm:
      case Abi.androidArm64:
      case Abi.androidIA32:
      case Abi.androidX64:
        return 'libisar.so';
      case Abi.macosArm64:
      case Abi.macosX64:
        return 'libisar.dylib';
      case Abi.linuxX64:
        return 'libisar.so';
      case Abi.windowsArm64:
      case Abi.windowsX64:
        return 'isar.dll';
      default:
        throw IsarError(
          'Unsupported processor architecture "${Abi.current()}". '
          'Please open an issue on GitHub to request it.',
        );
    }
  }
}
