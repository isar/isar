import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/src/native/binary/binary_reader.dart';
import 'package:isar/src/native/util/extensions.dart';

const _maxInt = 4294967295;

class BinaryWriter {
  static const utf8Encoder = Utf8Encoder();

  final Uint8List _buffer;

  final ByteData _byteData;

  int _offset = 0;

  int _dynamicOffset;

  BinaryWriter(Uint8List buffer, int staticSize)
      : _dynamicOffset = staticSize,
        _buffer = buffer,
        _byteData = ByteData.view(buffer.buffer);

  void skip(int bytes) {
    _offset += bytes;
  }

  void skipDynamic(int bytes) {
    _dynamicOffset += bytes;
  }

  void writeInt(int? value) {
    value ??= BinaryReader.nullInt;
    assert(value <= _maxInt, 'Illegal value for @Size32 field.');
    _buffer.writeInt32(_offset, value);
    _offset += 4;
  }

  void writeLong(int? value) {
    value ??= BinaryReader.nullInt;
    _buffer.writeInt64(_offset, value);
    _offset += 8;
  }

  void writeFloat(double? value) {
    value ??= double.nan;
    _byteData.setFloat32(_offset, value, Endian.little);
    _offset += 4;
  }

  void writeDouble(double? value) {
    value ??= double.nan;
    _byteData.setFloat64(_offset, value, Endian.little);
    _offset += 8;
  }

  void writeBool(bool? value) {
    if (value == null) {
      _buffer[_offset++] = 0;
    } else {
      _buffer[_offset++] = value ? 1 : 2;
    }
  }

  void writeBytes(Uint8List? value) {
    if (value == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      var bytesLen = value.length;
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, bytesLen);
      _buffer.setRange(_dynamicOffset, _dynamicOffset + bytesLen, value);
      _dynamicOffset += bytesLen;
    }

    _offset += 8;
  }

  void writeBoolList(List<bool?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);

      for (var value in values) {
        _buffer[_dynamicOffset++] = value == null
            ? BinaryReader.nullBool
            : value
                ? BinaryReader.trueBool
                : BinaryReader.falseBool;
      }
    }
    _offset += 8;
  }

  void writeIntList(List<int?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);

      for (var value in values) {
        _buffer.writeInt32(_dynamicOffset, value ?? BinaryReader.nullInt);
        _dynamicOffset += 4;
      }
    }
    _offset += 8;
  }

  void writeFloatList(List<double?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);

      for (var value in values) {
        _byteData.setFloat32(_dynamicOffset, value ?? double.nan);
        _dynamicOffset += 4;
      }
    }
    _offset += 8;
  }

  void writeLongList(List<int?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);

      for (var value in values) {
        _buffer.writeInt64(_dynamicOffset, value ?? BinaryReader.nullInt);
        _dynamicOffset += 8;
      }
    }
    _offset += 8;
  }

  void writeDoubleList(List<double?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);

      for (var value in values) {
        _byteData.setFloat64(_dynamicOffset, value ?? double.nan);
        _dynamicOffset += 8;
      }
    }
    _offset += 8;
  }

  void writeBytesList(List<Uint8List?>? values) {
    if (values == null) {
      _buffer.writeInt64(_offset, 0);
    } else {
      _buffer.writeInt32(_offset, _dynamicOffset);
      _buffer.writeInt32(_offset + 4, values.length);
      // TODO
    }

    _offset += 8;
  }
}
