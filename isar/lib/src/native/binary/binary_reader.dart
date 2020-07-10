import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/src/native/util/extensions.dart';

class BinaryReader {
  static const utf8Decoder = Utf8Decoder();
  static const nullInt = 1 << 64;

  final Uint8List _buffer;
  final ByteData _byteData;

  int _offset = 0;

  BinaryReader(this._buffer)
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes);

  int readInt() {
    var value = _buffer[_offset] |
        _buffer[_offset + 1] << 8 |
        _buffer[_offset + 2] << 16 |
        _buffer[_offset + 3] << 24 |
        _buffer[_offset + 4] << 32 |
        _buffer[_offset + 5] << 40 |
        _buffer[_offset + 6] << 48 |
        _buffer[_offset + 7] << 56;

    _offset += 8;
    return value;
  }

  int? readIntOrNull() {
    var value = readInt();
    if (value == nullInt) {
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

  bool readBool() {
    return _buffer[_offset++] == 1;
  }

  bool? readBoolOrNull() {
    var value = _buffer[_offset++];
    if (value == 0) {
      return null;
    } else if (value == 1) {
      return true;
    } else {
      return false;
    }
  }

  String readString() {
    var value = readStringOrNull();
    return value ?? '';
  }

  String? readStringOrNull() {
    var offset = _buffer.readUint32(_offset);
    if (offset == 0) {
      _offset += 8;
      return null;
    }

    var length = _buffer.readUint32(_offset + 4);
    _offset += 8;

    var view = _buffer.view(offset, length);
    return utf8Decoder.convert(view);
  }
}
