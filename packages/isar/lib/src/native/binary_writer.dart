import 'dart:convert';

import 'dart:typed_data';

import 'package:isar/src/native/isar_core.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
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

  @pragma('vm:prefer-inline')
  void writeBool(int offset, bool? value, {bool staticOffset = true}) {
    assert(!staticOffset || offset < _staticSize);
    if (value == null) {
      _buffer[offset] = nullBool;
    } else {
      _buffer[offset] = value ? trueBool : falseBool;
    }
  }

  @pragma('vm:prefer-inline')
  void writeInt(int offset, int? value) {
    assert(offset < _staticSize);
    value ??= nullInt;
    assert(value >= minInt && value <= maxInt);
    _byteData.setInt32(offset, value, Endian.little);
  }

  @pragma('vm:prefer-inline')
  void writeFloat(int offset, double? value) {
    assert(offset < _staticSize);
    _byteData.setFloat32(offset, value ?? double.nan, Endian.little);
  }

  @pragma('vm:prefer-inline')
  void writeLong(int offset, int? value) {
    assert(offset < _staticSize);
    _byteData.setInt64(offset, value ?? nullLong, Endian.little);
  }

  @pragma('vm:prefer-inline')
  void writeDouble(int offset, double? value) {
    assert(offset < _staticSize);
    _byteData.setFloat64(offset, value ?? double.nan, Endian.little);
  }

  @pragma('vm:prefer-inline')
  void writeDateTime(int offset, DateTime? value) {
    writeLong(offset, value?.toUtc().microsecondsSinceEpoch);
  }

  void _writeBytes(Uint8List? value, int offsetOffset, int dataOffset) {
    if (value == null) {
      _byteData.setUint32(offsetOffset, 0, Endian.little);
      _byteData.setUint32(offsetOffset + 4, 0, Endian.little);
    } else {
      var bytesLen = value.length;
      _byteData.setUint32(offsetOffset, dataOffset, Endian.little);
      _byteData.setUint32(offsetOffset + 4, bytesLen, Endian.little);
      _buffer.setRange(dataOffset, dataOffset + bytesLen, value);
    }
  }

  @pragma('vm:prefer-inline')
  void writeBytes(int offset, Uint8List? value) {
    assert(offset < _staticSize);
    _writeBytes(value, offset, _dynamicOffset);
    _dynamicOffset += value?.length ?? 0;
  }

  void writeBoolList(int offset, List<bool?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

      for (var value in values) {
        writeBool(_dynamicOffset++, value, staticOffset: false);
      }
    }
  }

  void writeIntList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

      for (var value in values) {
        value ??= nullInt;
        assert(value >= minInt && value <= maxInt);
        _byteData.setUint32(_dynamicOffset, value, Endian.little);
        _dynamicOffset += 4;
      }
    }
  }

  void writeFloatList(int offset, List<double?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

      for (var value in values) {
        _byteData.setFloat32(_dynamicOffset, value ?? nullFloat, Endian.little);
        _dynamicOffset += 4;
      }
    }
  }

  void writeLongList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

      for (var value in values) {
        _byteData.setInt64(_dynamicOffset, value ?? nullLong, Endian.little);
        _dynamicOffset += 8;
      }
    }
  }

  void writeDoubleList(int offset, List<double?>? values) {
    assert(offset < _staticSize);
    if (values == null) {
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

      for (var value in values) {
        _byteData.setFloat64(
            _dynamicOffset, value ?? nullDouble, Endian.little);
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
      _byteData.setUint32(offset, 0, Endian.little);
      _byteData.setUint32(offset + 4, 0, Endian.little);
    } else {
      _byteData.setUint32(offset, _dynamicOffset, Endian.little);
      _byteData.setUint32(offset + 4, values.length, Endian.little);

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
