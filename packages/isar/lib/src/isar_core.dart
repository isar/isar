part of isar;

abstract final class IsarCore {
  static var _initialized = false;

  static Pointer<Pointer<NativeType>> ptrPtr = malloc<Pointer>();
  static Pointer<Uint32> countPtr = malloc<Uint32>();
  static Pointer<Bool> boolPtr = malloc<Bool>();

  static late final Pointer<Pointer<Uint8>> stringPtrPtr = ptrPtr.cast();
  static Pointer<Uint8> get stringPtr => stringPtrPtr.value;

  static late final Pointer<Pointer<CIsarReader>> readerPtrPtr = ptrPtr.cast();
  static Pointer<CIsarReader> get readerPtr => readerPtrPtr.value;

  static Pointer<Uint16> _nativeStringPtr = nullptr;
  static int _nativeStringPtrLength = 0;

  static void _initialize({Map<Abi, String> libraries = const {}}) {
    if (_initialized) {
      return;
    }

    String? libraryPath;
    if (!Platform.isIOS) {
      libraryPath = libraries[Abi.current()] ?? Abi.current().localName;
    }

    try {
      if (Platform.isIOS) {
        DynamicLibrary.process();
      } else {
        DynamicLibrary.open(libraryPath!);
      }
    } catch (e) {
      throw IsarNotReadyError(
        'Could not initialize IsarCore library for processor architecture '
        '"${Abi.current()}". If you create a Flutter app, make sure to add '
        'isar_flutter_libs to your dependencies. For Dart-only apps or unit '
        'tests, make sure to place the correct Isar binary in the correct '
        'directory.\n$e',
      );
    }

    final coreVersion = isar_version().cast<Utf8>().toDartString();
    if (coreVersion != Isar.version && coreVersion != 'debug') {
      throw IsarNotReadyError(
        'Incorrect Isar Core version: Required ${Isar.version} found '
        '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
        'have a Dart only project, make sure that old Isar Core binaries are '
        'deleted.',
      );
    }

    _initialized = true;
  }

  static void _free() {
    malloc.free(ptrPtr);
    malloc.free(countPtr);
    malloc.free(boolPtr);
    if (!_nativeStringPtr.isNull) {
      malloc.free(_nativeStringPtr);
    }
  }

  static Pointer<CString> toNativeString(String str) {
    if (_nativeStringPtrLength < str.length) {
      if (_nativeStringPtr != nullptr) {
        malloc.free(_nativeStringPtr);
      }
      _nativeStringPtr = malloc<Uint16>(str.length);
      _nativeStringPtrLength = str.length;
    }

    final list = _nativeStringPtr.asTypedList(str.length);
    for (var i = 0; i < str.length; i++) {
      list[i] = str.codeUnitAt(i);
    }

    return isar_string(_nativeStringPtr, str.length);
  }

  static const isarReadId = isar_read_id;
  static const isarReadNull = isar_read_null;
  static const isarReadBool = isar_read_bool;
  static const isarReadByte = isar_read_byte;
  static const isarReadInt = isar_read_int;
  static const isarReadFloat = isar_read_float;
  static const isarReadLong = isar_read_long;
  static const isarReadDouble = isar_read_double;
  static String? isarReadString(Pointer<CIsarReader> reader, int index) {
    final length = isar_read_string(reader, index, stringPtrPtr, boolPtr);
    if (stringPtr.isNull) {
      return null;
    } else {
      final bytes = stringPtr.asTypedList(length);
      if (boolPtr.value) {
        return String.fromCharCodes(bytes);
      } else {
        return utf8.decode(bytes);
      }
    }
  }

  static const isarReadObject = isar_read_object;
  static const isarReadList = isar_read_list;

  static const isarWriteNull = isar_write_null;
  static const isarWriteBool = isar_write_bool;
  static const isarWriteByte = isar_write_byte;
  static const isarWriteInt = isar_write_int;
  static const isarWriteFloat = isar_write_float;
  static const isarWriteLong = isar_write_long;
  static const isarWriteDouble = isar_write_double;
  static const isarWriteString = isar_write_string;
  static const isarBeginObject = isar_begin_object;
  static const isarEndObject = isar_end_object;
  static const isarBeginList = isar_begin_list;
  static const isarEndList = isar_end_list;
}

extension _NativeError on int {
  @pragma('vm:prefer-inline')
  void checkNoError() {
    if (this != 0) {
      throwError();
    }
  }

  Never throwError() {
    switch (this) {
      case ERROR_PATH:
        throw PathError();
      case ERROR_UNIQUE_VIOLATED:
        throw UniqueViolationError();
      case ERROR_WRITE_TXN_REQUIRED:
        throw WriteTxnRequiredError();
      case ERROR_VERSION:
        throw VersionError();
      case ERROR_OBJECT_LIMIT_REACHED:
        throw ObjectLimitReachedError();
      case ERROR_INSTANCE_MISMATCH:
        throw InstanceMismatchError();
      case ERROR_DB_FULL:
        throw DatabaseFullError();
      default:
        final length = isar_get_error(IsarCore.stringPtrPtr);
        final ptr = IsarCore.stringPtr;
        if (length != 0 && !ptr.isNull) {
          final length = IsarCore.countPtr.value;
          final error = utf8.decode(ptr.asTypedList(length));
          throw DatabaseError(error);
        } else {
          throw DatabaseError(
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
      case Abi.androidIA32:
        throw IsarNotReadyError(
          'Unsupported processor architecture. X86 Android emulators are not '
          'supported. Please use an x86_64 emulator instead. All physical '
          'Android devices are supported including 32bit ARM.',
        );
      default:
        throw IsarNotReadyError(
          'Unsupported processor architecture "${Abi.current()}". '
          'Please open an issue on GitHub to request it.',
        );
    }
  }
}
