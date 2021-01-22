part of isar_native;

class BinaryReader {
  static const utf8Decoder = Utf8Decoder();

  final Uint8List _buffer;
  final ByteData _byteData;

  int _offset = 0;

  BinaryReader(this._buffer)
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes);

  void skip(int bytes) {
    _offset += bytes;
  }

  bool readBool() {
    return _buffer[_offset++] == trueBool;
  }

  bool? readBoolOrNull() {
    final value = _buffer[_offset++];
    if (value == nullBool) {
      return null;
    } else if (value == trueBool) {
      return true;
    } else {
      return false;
    }
  }

  int readInt() {
    final value = _byteData.getInt32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  int? readIntOrNull() {
    final value = readInt();
    if (value == nullInt) {
      return null;
    } else {
      return value;
    }
  }

  double readFloat() {
    var value = _byteData.getFloat32(_offset, Endian.little);
    _offset += 4;
    return value;
  }

  double? readFloatOrNull() {
    var value = readFloat();
    if (value.isNaN) {
      return null;
    } else {
      return value;
    }
  }

  int readLong() {
    final value = _byteData.getInt64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  int? readLongOrNull() {
    final value = readLong();
    if (value == nullLong) {
      return null;
    } else {
      return value;
    }
  }

  double readDouble() {
    final value = _byteData.getFloat64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  double? readDoubleOrNull() {
    final value = readDouble();
    if (value.isNaN) {
      return null;
    } else {
      return value;
    }
  }

  Uint8List? _readBytesOrNullAt(int bytesOffset) {
    final offset = _buffer.readInt32(bytesOffset);
    if (offset == 0) {
      return null;
    }
    final length = _buffer.readInt32(bytesOffset + 4);
    return _buffer.view(offset, length);
  }

  String? _readStringOrNullAt(int stringOffset) {
    final bytes = _readBytesOrNullAt(stringOffset);
    if (bytes != null) {
      return utf8Decoder.convert(bytes);
    }
  }

  String readString() {
    final value = _readStringOrNullAt(_offset);
    _offset += 8;
    return value ?? '';
  }

  String? readStringOrNull() {
    final value = _readStringOrNullAt(_offset);
    _offset += 8;
    return value;
  }

  Uint8List readBytes() {
    final value = _readBytesOrNullAt(_offset);
    _offset += 8;
    return value!;
  }

  Uint8List? readBytesOrNull() {
    final value = _readBytesOrNullAt(_offset);
    _offset += 8;
    return value;
  }

  bool skipListIfNull() {
    final offset = _buffer.readInt32(_offset);
    if (offset == 0) {
      _offset += 8;
      return true;
    } else {
      return false;
    }
  }

  List<bool> readBoolList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <bool>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer[offset + i] == trueBool;
    }
    return list;
  }

  List<bool?> readBoolOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <bool?>[];
    for (var i = 0; i < length; i++) {
      final value = _buffer[offset + i];
      if (value == trueBool) {
        list[i] = true;
      } else if (value == falseBool) {
        list[i] = false;
      }
    }
    return list;
  }

  List<int> readIntList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt32(offset + i * 4);
    }
    return list;
  }

  List<int?> readIntOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int?>[];
    for (var i = 0; i < length; i++) {
      final value = _buffer.readInt32(offset + i * 4);
      if (value != nullInt) {
        list[i] = value;
      }
    }
    return list;
  }

  List<double> readFloatList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat32(offset + i * 4, Endian.little);
    }
    return list;
  }

  List<double?> readFloatOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double?>[];
    for (var i = 0; i < length; i++) {
      final value = _byteData.getFloat32(offset + i * 4, Endian.little);
      if (!value.isNaN) {
        list[i] = value;
      }
    }
    return list;
  }

  List<int> readLongList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt64(offset + i * 8);
    }
    return list;
  }

  List<int?> readLongOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int?>[];
    for (var i = 0; i < length; i++) {
      final value = _buffer.readInt64(offset + i * 8);
      if (value != nullLong) {
        list[i] = value;
      }
    }
    return list;
  }

  List<double> readDoubleList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(offset + i * 8, Endian.little);
    }
    return list;
  }

  List<double?> readDoubleOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double?>[];
    for (var i = 0; i < length; i++) {
      final value = _byteData.getFloat64(offset + i * 8, Endian.little);
      if (!value.isNaN) {
        list[i] = value;
      }
    }
    return list;
  }

  List<String?> readStringOrNullList() {
    final offset = _buffer.readInt32(_offset);
    final length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <String?>[];
    for (var i = 0; i < length; i++) {
      list[i] = _readStringOrNullAt(offset + i * 8);
    }
    return list;
  }

  List<String> readStringList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <String>[];
    for (var i = 0; i < length; i++) {
      list[i] = _readStringOrNullAt(offset + i * 8) ?? '';
    }
    return list;
  }
}
