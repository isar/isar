part of isar_native;

class BinaryWriter {
  static const utf8Encoder = Utf8Encoder();

  final Uint8List _buffer;

  final ByteData _byteData;

  final int _staticSize;

  int _dynamicOffset;

  BinaryWriter(Uint8List buffer, int staticSize)
      : _staticSize = staticSize,
        _dynamicOffset = staticSize,
        _buffer = buffer,
        _byteData = ByteData.view(buffer.buffer) {
    _byteData.setUint16(0, staticSize, Endian.little);
  }

  void writeBool(int offset, bool? value, {bool staticOffset = true}) {
    assert(!staticOffset || offset < _staticSize);
    if (value == null) {
      _buffer[offset] = nullBool;
    } else {
      _buffer[offset] = value ? trueBool : falseBool;
    }
  }

  void writeInt(int offset, int? value) {
    assert(offset < _staticSize);
    value ??= nullInt;
    assert(value >= minInt && value <= maxInt);
    _byteData.setInt32(offset, value, Endian.little);
  }

  void writeFloat(int offset, double? value) {
    assert(offset < _staticSize);
    value ??= double.nan;
    _byteData.setFloat32(offset, value, Endian.little);
  }

  void writeLong(int offset, int? value) {
    assert(offset < _staticSize);
    value ??= nullLong;
    _byteData.setInt64(offset, value, Endian.little);
  }

  void writeDouble(int offset, double? value) {
    assert(offset < _staticSize);
    value ??= double.nan;
    _byteData.setFloat64(offset, value, Endian.little);
  }

  void writeDateTime(int offset, DateTime? value) {
    writeLong(offset, value?.toUtc().microsecondsSinceEpoch);
  }

  void _writeBytes(Uint8List? value, int offsetOffset, int dataOffset) {
    if (value == null) {
      _buffer.writeInt64(offsetOffset, 0);
    } else {
      var bytesLen = value.length;
      _buffer.writeInt32(offsetOffset, dataOffset);
      _buffer.writeInt32(offsetOffset + 4, bytesLen);
      _buffer.setRange(dataOffset, dataOffset + bytesLen, value);
    }
  }

  void writeBytes(int offset, Uint8List? value) {
    assert(offset < _staticSize);
    _writeBytes(value, offset, _dynamicOffset);
    _dynamicOffset += value?.length ?? 0;
  }

  void writeBoolList(int offset, List<bool?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      for (var value in values) {
        writeBool(_dynamicOffset++, value, staticOffset: false);
      }
    }
  }

  void writeIntList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      for (var value in values) {
        value ??= nullInt;
        assert(value >= minInt && value <= maxInt);
        _buffer.writeInt32(_dynamicOffset, value);
        _dynamicOffset += 4;
      }
    }
  }

  void writeFloatList(int offset, List<double?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      for (var value in values) {
        _byteData.setFloat32(_dynamicOffset, value ?? nullFloat);
        _dynamicOffset += 4;
      }
    }
  }

  void writeLongList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      for (var value in values) {
        _buffer.writeInt64(_dynamicOffset, value ?? nullLong);
        _dynamicOffset += 8;
      }
    }
  }

  void writeDoubleList(int offset, List<double?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      for (var value in values) {
        _byteData.setFloat64(_dynamicOffset, value ?? nullDouble);
        _dynamicOffset += 8;
      }
    }
  }

  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final longList =
        values?.map((e) => e?.toUtc().microsecondsSinceEpoch).toList();
    writeLongList(offset, longList);
  }

  void writeStringList(int offset, List<Uint8List?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _buffer.writeInt64(offset, 0);
    } else {
      _buffer.writeInt32(offset, _dynamicOffset);
      _buffer.writeInt32(offset + 4, values.length);

      final offsetListOffset = _dynamicOffset;
      _dynamicOffset += values.length * 8;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        _writeBytes(value, offsetListOffset + i * 8, _dynamicOffset);
        _dynamicOffset += value?.length ?? 0;
      }
    }
  }
}
