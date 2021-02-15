part of isar_native;

class BinaryReader {
  static const utf8Decoder = Utf8Decoder();

  final Uint8List _buffer;
  final ByteData _byteData;
  late int _staticSize;

  BinaryReader(this._buffer)
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes) {
    _staticSize = _byteData.getUint16(0, Endian.little);
  }

  bool readBool(int offset, {bool staticOffset = true}) {
    return readBoolOrNull(offset, staticOffset: staticOffset) ?? false;
  }

  bool? readBoolOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final value = _buffer[offset];
    if (value == trueBool) {
      return true;
    } else if (value == falseBool) {
      return false;
    }
  }

  int readInt(int offset, {bool staticOffset = true}) {
    return readIntOrNull(offset, staticOffset: staticOffset) ?? nullInt;
  }

  int? readIntOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final value = _byteData.getInt32(offset, Endian.little);
    if (value != nullInt) {
      return value;
    }
  }

  double readFloat(int offset, {bool staticOffset = true}) {
    return readFloatOrNull(offset, staticOffset: staticOffset) ?? nullFloat;
  }

  double? readFloatOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    var value = _byteData.getFloat32(offset, Endian.little);
    if (!value.isNaN) {
      return value;
    }
  }

  int readLong(int offset, {bool staticOffset = true}) {
    return readLongOrNull(offset, staticOffset: staticOffset) ?? nullLong;
  }

  int? readLongOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final value = _byteData.getInt64(offset, Endian.little);
    if (value != nullLong) {
      return value;
    }
  }

  double readDouble(int offset, {bool staticOffset = true}) {
    return readDoubleOrNull(offset, staticOffset: staticOffset) ?? nullDouble;
  }

  double? readDoubleOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final value = _byteData.getFloat64(offset, Endian.little);
    if (!value.isNaN) {
      return value;
    }
  }

  DateTime readDateTime(int offset, {bool staticOffset = true}) {
    return readDateTimeOrNull(offset, staticOffset: staticOffset) ?? nullDate;
  }

  DateTime? readDateTimeOrNull(int offset, {bool staticOffset = true}) {
    final time = readLongOrNull(offset, staticOffset: staticOffset);
    if (time != null) {
      return DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal();
    }
  }

  String readString(int offset, {bool staticOffset = true}) {
    return readStringOrNull(offset, staticOffset: staticOffset) ?? '';
  }

  String? readStringOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final bytesOffset = _buffer.readInt32(offset);
    if (bytesOffset == 0) {
      return null;
    }
    final length = _buffer.readInt32(offset + 4);

    return utf8Decoder.convert(_buffer, bytesOffset, bytesOffset + length);
  }

  Uint8List readBytes(int offset, {bool staticOffset = true}) {
    return readBytesOrNull(offset, staticOffset: staticOffset) ??
        Uint8List.fromList([]);
  }

  Uint8List? readBytesOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) return null;
    final bytesOffset = _buffer.readInt32(offset);
    if (bytesOffset == 0) {
      return null;
    }
    final length = _buffer.readInt32(offset + 4);
    return _buffer.view(bytesOffset, length);
  }

  List<bool>? readBoolList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <bool>[];
    for (var i = 0; i < length; i++) {
      list[i] = readBool(listOffset + i, staticOffset: false);
    }
    return list;
  }

  List<bool?>? readBoolOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <bool?>[];
    for (var i = 0; i < length; i++) {
      list[i] = readBool(listOffset + i, staticOffset: false);
    }
    return list;
  }

  List<int>? readIntList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt32(listOffset + i * 4);
    }
    return list;
  }

  List<int?>? readIntOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <int?>[];
    for (var i = 0; i < length; i++) {
      list[i] = readIntOrNull(listOffset + i * 4, staticOffset: false);
    }
    return list;
  }

  List<double>? readFloatList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat32(listOffset + i * 4, Endian.little);
    }
    return list;
  }

  List<double?>? readFloatOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <double?>[];
    for (var i = 0; i < length; i++) {
      list[i] = readFloatOrNull(listOffset + i * 4, staticOffset: false);
    }
    return list;
  }

  List<int>? readLongList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt64(listOffset + i * 8);
    }
    return list;
  }

  List<int?>? readLongOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <int?>[];
    for (var i = 0; i < length; i++) {
      list[i] = readLongOrNull(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }

  List<double>? readDoubleList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(listOffset + i * 8, Endian.little);
    }
    return list;
  }

  List<double?>? readDoubleOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    final listOffset = _buffer.readInt32(offset);
    final length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <double?>[];
    for (var i = 0; i < length; i++) {
      list[i] = readDoubleOrNull(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }

  List<DateTime>? readDateTimeList(int offset) {
    return readLongOrNullList(offset)?.map((e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      } else {
        return nullDate;
      }
    }).toList();
  }

  List<DateTime?>? readDateTimeOrNullList(int offset) {
    return readLongOrNullList(offset)?.map((e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      }
    }).toList();
  }

  List<String>? readStringList(int offset) {
    if (offset >= _staticSize) return [];

    var listOffset = _buffer.readInt32(offset);
    var length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <String>[];
    for (var i = 0; i < length; i++) {
      list.add(readString(listOffset + i * 8, staticOffset: false));
    }
    return list;
  }

  List<String?>? readStringOrNullList(int offset) {
    if (offset >= _staticSize) return [];

    var listOffset = _buffer.readInt32(offset);
    var length = _buffer.readInt32(offset + 4);
    if (listOffset == 0) return null;

    final list = <String?>[];
    for (var i = 0; i < length; i++) {
      list.add(readStringOrNull(listOffset + i * 8, staticOffset: false));
    }
    return list;
  }
}
