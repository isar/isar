// ignore_for_file: public_member_api_docs

part of isar;

abstract final class IsarCore {
  static var _initialized = false;
  static String? _libraryPath;

  static late final IsarCoreBindings b;

  static Pointer<Pointer<NativeType>> ptrPtr = malloc<Pointer<NativeType>>();
  static Pointer<Uint32> countPtr = malloc<Uint32>();
  static Pointer<Bool> boolPtr = malloc<Bool>();

  static final Pointer<Pointer<Uint8>> stringPtrPtr =
      ptrPtr.cast<Pointer<Uint8>>();
  static Pointer<Uint8> get stringPtr => stringPtrPtr.ptrValue;

  static final Pointer<Pointer<CIsarReader>> readerPtrPtr =
      ptrPtr.cast<Pointer<CIsarReader>>();
  static Pointer<CIsarReader> get readerPtr => readerPtrPtr.ptrValue;

  static Pointer<Uint16> _nativeStringPtr = nullptr;
  static int _nativeStringPtrLength = 0;

  static FutureOr<void> _initialize([String? libraryPath]) {
    if (_initialized) {
      return null;
    }

    final result = initializePlatformBindings(libraryPath);
    if (result is Future) {
      return (result as Future<IsarCoreBindings>).then((bindings) {
        b = bindings;
        _libraryPath = libraryPath;
        _initialized = true;
      });
    } else {
      b = result;
      _libraryPath = libraryPath;
      _initialized = true;
    }
  }

  static void _free() {
    free(ptrPtr);
    free(countPtr);
    free(boolPtr);
    if (!_nativeStringPtr.isNull) {
      free(_nativeStringPtr);
    }
  }

  static Pointer<CString> toNativeString(String str) {
    if (_nativeStringPtrLength < str.length) {
      if (_nativeStringPtr != nullptr) {
        free(_nativeStringPtr);
      }
      _nativeStringPtr = malloc<Uint16>(str.length);
      _nativeStringPtrLength = str.length;
    }

    final list = _nativeStringPtr.asU16List(str.length);
    for (var i = 0; i < str.length; i++) {
      list[i] = str.codeUnitAt(i);
    }

    return b.isar_string(_nativeStringPtr, str.length);
  }

  static final readId = b.isar_read_id;
  static bool readNull(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_null(reader, index) != 0;
  }

  static bool readBool(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_bool(reader, index) != 0;
  }

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
      final bytes = stringPtr.asU8List(length);
      if (boolPtr.boolValue) {
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
}

extension PointerX on Pointer<void> {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}

const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');
