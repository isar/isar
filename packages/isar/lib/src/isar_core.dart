// ignore_for_file: public_member_api_docs

part of isar;

abstract final class IsarCore {
  static var _initialized = false;
  static String? _libraryPath;

  static late final IsarCoreBindings b;

  static Pointer<Pointer<NativeType>> ptrPtr = malloc<Pointer>();
  static Pointer<Uint32> countPtr = malloc<Uint32>();
  static Pointer<Bool> boolPtr = malloc<Bool>();

  static final Pointer<Pointer<Uint8>> stringPtrPtr = ptrPtr.cast();
  static Pointer<Uint8> get stringPtr => stringPtrPtr.value;

  static final Pointer<Pointer<CIsarReader>> readerPtrPtr = ptrPtr.cast();
  static Pointer<CIsarReader> get readerPtr => readerPtrPtr.value;

  static Pointer<Uint16> _nativeStringPtr = nullptr;
  static int _nativeStringPtrLength = 0;

  static void _openDylib(String? libraryPath) {
    _libraryPath =
        Platform.isIOS ? null : libraryPath ?? Abi.current().localName;

    final dylib = Platform.isIOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open(_libraryPath!);
    close = dylib.lookup('isar_close');
    b = IsarCoreBindings(dylib);

    IsarCore.b.isar_connect_dart_api(NativeApi.postCObject.cast());
  }

  static void _initialize({Map<Abi, String> libraries = const {}}) {
    if (_initialized) {
      return;
    }

    try {
      _openDylib(libraries[Abi.current()] ?? _libraryPath);
    } catch (e) {
      throw IsarNotReadyError(
        'Could not initialize IsarCore library for processor architecture '
        '"${Abi.current()}". If you create a Flutter app, make sure to add '
        'isar_flutter_libs to your dependencies. For Dart-only apps or unit '
        'tests, make sure to place the correct Isar binary in the correct '
        'directory.\n$e',
      );
    }

    final coreVersion = b.isar_version().cast<Utf8>().toDartString();
    if (coreVersion != Isar.version && coreVersion != 'debug') {
      throw IsarNotReadyError(
        'Incorrect Isar Core version: Required ${Isar.version} found '
        '$coreVersion. Make sure to use the latest isar_flutter_libs. If you '
        'have a Dart only project, make sure that old Isar Core binaries are '
        'deleted.',
      );
    }

    IsarCore.b.isar_connect_dart_api(NativeApi.postCObject.cast());
    _initialized = true;
  }

  static void _attach(String? libraryPath) {
    if (_initialized) {
      return;
    }
    _openDylib(_libraryPath);
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

    return b.isar_string(_nativeStringPtr, str.length);
  }

  static final readId = b.isar_read_id;
  static final readNull = b.isar_read_null;
  static final readBool = b.isar_read_bool;
  static final readByte = b.isar_read_byte;
  static final readInt = b.isar_read_int;
  static final readFloat = b.isar_read_float;
  static final readLong = b.isar_read_long;
  static final readDouble = b.isar_read_double;
  static String? readString(Pointer<CIsarReader> reader, int index) {
    final length = b.isar_read_string(reader, index, stringPtrPtr, boolPtr);
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

  static final readObject = b.isar_read_object;
  static final readList = b.isar_read_list;
  static final freeReader = b.isar_read_free;

  static final writeNull = b.isar_write_null;
  static final writeBool = b.isar_write_bool;
  static final writeByte = b.isar_write_byte;
  static final writeInt = b.isar_write_int;
  static final writeFloat = b.isar_write_float;
  static final writeLong = b.isar_write_long;
  static final writeDouble = b.isar_write_double;
  static final writeString = b.isar_write_string;
  static final beginObject = b.isar_write_object;
  static final endObject = b.isar_write_object_end;
  static final beginList = b.isar_write_list;
  static final endList = b.isar_write_list_end;

  static late final Pointer<NativeFinalizerFunction> close;
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
