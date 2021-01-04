part of isar_native;

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

  void pad(int bytes) {
    _offset += bytes;
  }

  void padDynamic(int bytes) {
    _dynamicOffset += bytes;
  }

  void writeInt(int? value) {
    value ??= nullInt;
    _byteData.setInt32(_offset, value, Endian.little);
    _offset += 4;
  }

  void writeLong(int? value) {
    value ??= nullLong;
    _byteData.setInt64(_offset, value, Endian.little);
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
      _buffer[_offset++] = nullBool;
    } else {
      _buffer[_offset++] = value ? trueBool : falseBool;
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
            ? nullBool
            : value
                ? trueBool
                : falseBool;
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
        _buffer.writeInt32(_dynamicOffset, value ?? nullInt);
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
        _byteData.setFloat32(_dynamicOffset, value ?? nullFloat);
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
        _buffer.writeInt64(_dynamicOffset, value ?? nullLong);
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
        _byteData.setFloat64(_dynamicOffset, value ?? nullDouble);
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
