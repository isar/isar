import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/src/native/util/extensions.dart';

class BinaryReader {
  static const utf8Decoder = Utf8Decoder();
  static const nullInt = 1 << 32;
  static const nullLong = 1 << 64;
  static const nullBool = 0;
  static const trueBool = 1;
  static const falseBool = 2;

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
    var value = _buffer[_offset++];
    if (value == nullBool) {
      return null;
    } else if (value == trueBool) {
      return true;
    } else {
      return false;
    }
  }

  int readInt() {
    final value = _buffer.readInt32(_offset);
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
    var value = _buffer.readInt64(_offset);
    _offset += 8;
    return value;
  }

  int? readLongOrNull() {
    var value = readLong();
    if (value == nullLong) {
      return null;
    } else {
      return value;
    }
  }

  double readDouble() {
    var value = _byteData.getFloat64(_offset, Endian.little);
    _offset += 8;
    return value;
  }

  double? readDoubleOrNull() {
    var value = readDouble();
    if (value.isNaN) {
      return null;
    } else {
      return value;
    }
  }

  String readString() {
    var value = readStringOrNull();
    return value ?? '';
  }

  String? readStringOrNull() {
    var offset = _buffer.readInt32(_offset);
    if (offset == 0) {
      _offset += 8;
      return null;
    }

    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    var view = _buffer.view(offset, length);
    return utf8Decoder.convert(view);
  }

  bool skipListIfNull() {
    var offset = _buffer.readInt32(_offset);
    if (offset == 0) {
      _offset += 8;
      return true;
    } else {
      return false;
    }
  }

  List<bool> readBoolList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <bool>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer[offset + i] == trueBool;
    }
    return list;
  }

  List<bool?> readBoolOrNullList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
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

  List<Uint8List> readBytesList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <Uint8List>[];
    for (var i = 0; i < length; i++) {
      var elementOffset = _buffer.readInt32(offset + i * 8);
      var elementLength = _buffer.readInt32(_offset + i * 8 + 4);
      final bytes = _buffer.view(elementOffset, elementLength);
      list[i] = bytes.sublist(0);
    }
    return list;
  }

  List<int> readIntList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt32(offset + i * 4);
    }
    return list;
  }

  List<int?> readIntOrNullList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
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
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat32(offset + i * 4, Endian.little);
    }
    return list;
  }

  List<double?> readFloatOrNullList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
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
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <int>[];
    for (var i = 0; i < length; i++) {
      list[i] = _buffer.readInt64(offset + i * 8);
    }
    return list;
  }

  List<int?> readLongOrNullList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
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
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
    _offset += 8;

    final list = <double>[];
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(offset + i * 8, Endian.little);
    }
    return list;
  }

  List<double?> readDoubleOrNullList() {
    var offset = _buffer.readInt32(_offset);
    var length = _buffer.readInt32(_offset + 4);
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
}
