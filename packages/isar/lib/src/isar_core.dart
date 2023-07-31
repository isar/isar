// ignore_for_file: public_member_api_docs

part of isar;

abstract final class IsarCore {
  static const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

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

  static Pointer<CString> _toNativeString(String str) {
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

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int readId(Pointer<CIsarReader> reader) {
    return b.isar_read_id(reader);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static bool readNull(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_null(reader, index) != 0;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static bool readBool(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_bool(reader, index) != 0;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int readByte(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_byte(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int readInt(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_int(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static double readFloat(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_float(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int readLong(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_long(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static double readDouble(Pointer<CIsarReader> reader, int index) {
    return b.isar_read_double(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
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

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static Pointer<CIsarReader> readObject(
    Pointer<CIsarReader> reader,
    int index,
  ) {
    return b.isar_read_object(reader, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static int readList(
    Pointer<CIsarReader> reader,
    int index,
    Pointer<Pointer<CIsarReader>> listReader,
  ) {
    return b.isar_read_list(reader, index, listReader);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void freeReader(Pointer<CIsarReader> reader) {
    b.isar_read_free(reader);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeNull(Pointer<CIsarWriter> writer, int index) {
    b.isar_write_null(writer, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeBool(Pointer<CIsarWriter> writer, int index, bool value) {
    b.isar_write_bool(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeByte(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_byte(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeInt(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_int(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeFloat(Pointer<CIsarWriter> writer, int index, double value) {
    b.isar_write_float(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeLong(Pointer<CIsarWriter> writer, int index, int value) {
    b.isar_write_long(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeDouble(
    Pointer<CIsarWriter> writer,
    int index,
    double value,
  ) {
    b.isar_write_double(writer, index, value);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void writeString(
    Pointer<CIsarWriter> writer,
    int index,
    String value,
  ) {
    final valuePtr = _toNativeString(value);
    b.isar_write_string(writer, index, valuePtr);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static Pointer<CIsarWriter> beginObject(
    Pointer<CIsarWriter> writer,
    int index,
  ) {
    return b.isar_write_object(writer, index);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void endObject(
    Pointer<CIsarWriter> writer,
    Pointer<CIsarWriter> objectWriter,
  ) {
    b.isar_write_object_end(writer, objectWriter);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static Pointer<CIsarWriter> beginList(
    Pointer<CIsarWriter> writer,
    int index,
    int length,
  ) {
    return b.isar_write_list(writer, index, length);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  static void endList(
    Pointer<CIsarWriter> writer,
    Pointer<CIsarWriter> listWriter,
  ) {
    b.isar_write_list_end(writer, listWriter);
  }
}

extension PointerX on Pointer<void> {
  @pragma('vm:prefer-inline')
  bool get isNull => address == 0;
}
