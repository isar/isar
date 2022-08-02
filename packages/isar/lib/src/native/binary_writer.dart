// ignore_for_file: public_member_api_docs, prefer_asserts_with_message,
// avoid_positional_boolean_parameters

import 'dart:typed_data';

import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
class BinaryWriter {
  BinaryWriter(Uint8List buffer, int staticSize)
      : _staticSize = staticSize,
        _dynamicOffset = staticSize,
        _buffer = buffer,
        _byteData = ByteData.view(buffer.buffer, buffer.offsetInBytes);

  final Uint8List _buffer;

  final ByteData _byteData;

  final int _staticSize;

  int _dynamicOffset;

  int get usedBytes => _dynamicOffset;

  @pragma('vm:prefer-inline')
  void writeHeader() {
    _byteData.setUint16(0, _staticSize, Endian.little);
  }

  @pragma('vm:prefer-inline')
  void writeBool(int offset, bool? value) {
    assert(offset < _staticSize);
    _buffer[offset] = value.byteValue;
  }

  @pragma('vm:prefer-inline')
  void writeByte(int offset, int? value) {
    assert(offset < _staticSize);
    value ??= nullByte;
    assert(value >= minByte && value <= maxByte);
    _buffer[offset] = value;
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

  @pragma('vm:prefer-inline')
  void writeEnum(int offset, Enum? value) {
    writeByte(offset, (value?.index ?? -1) + 1);
  }

  @pragma('vm:prefer-inline')
  void _writeUint24(int offset, int value) {
    _buffer[offset] = value;
    _buffer[offset + 1] = value >> 8;
    _buffer[offset + 2] = value >> 16;
  }

  @pragma('vm:prefer-inline')
  void writeString(int offset, String? value) {
    assert(offset < _staticSize);
    if (value != null) {
      final byteCount = encodeString(value, _buffer, _dynamicOffset + 3);
      _writeUint24(offset, _dynamicOffset);
      _writeUint24(_dynamicOffset, byteCount);
      _dynamicOffset += byteCount + 3;
    } else {
      _writeUint24(offset, 0);
    }
  }

  @pragma('vm:prefer-inline')
  void _writeListOffset(int offset, int? length) {
    if (length == null) {
      _writeUint24(offset, 0);
    } else {
      _writeUint24(offset, _dynamicOffset);
      _writeUint24(_dynamicOffset, length);
      _dynamicOffset += 3;
    }
  }

  @pragma('vm:prefer-inline')
  void writeByteList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _buffer[_dynamicOffset++] = values[i] ?? nullByte;
      }
    }
  }

  void writeBoolList(int offset, List<bool?>? values) {
    assert(offset < _staticSize);
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _buffer[_dynamicOffset++] = values[i].byteValue;
      }
    }
  }

  void writeIntList(int offset, List<int?>? values) {
    assert(offset < _staticSize);
    _writeListOffset(offset, values?.length);

    if (values != null) {
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
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _byteData.setFloat32(
          _dynamicOffset,
          values[i] ?? nullFloat,
          Endian.little,
        );
        _dynamicOffset += 4;
      }
    }
  }

  void writeLongList(int offset, List<int?>? values) {
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _byteData.setInt64(
          _dynamicOffset,
          values[i] ?? nullLong,
          Endian.little,
        );
        _dynamicOffset += 8;
      }
    }
  }

  void writeDoubleList(int offset, List<double?>? values) {
    assert(offset < _staticSize);
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _byteData.setFloat64(
          _dynamicOffset,
          values[i] ?? nullDouble,
          Endian.little,
        );
        _dynamicOffset += 8;
      }
    }
  }

  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final longList = values?.map((e) => e.longValue).toList();
    writeLongList(offset, longList);
  }

  void writeEnumList(int offset, List<Enum?>? values) {
    final byteList = values?.map((e) => e.byteValue).toList();
    writeByteList(offset, byteList);
  }

  void writeStringList(int offset, List<String?>? values) {
    assert(offset < _staticSize);
    _writeListOffset(offset, values?.length);

    if (values != null) {
      final offsetListOffset = _dynamicOffset;
      _dynamicOffset += values.length * 3;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        if (value != null) {
          final byteCount = encodeString(value, _buffer, _dynamicOffset);
          _writeUint24(offsetListOffset + i * 3, byteCount + 1);
          _dynamicOffset += byteCount;
        } else {
          _writeUint24(offsetListOffset + i * 3, 0);
        }
      }
    }
  }
}

extension IsarBoolValue on bool? {
  @pragma('vm:prefer-inline')
  int get byteValue =>
      this == null ? nullBool : (this == true ? trueBool : falseBool);
}

extension IsarEnumValue on Enum? {
  @pragma('vm:prefer-inline')
  int get byteValue => (this?.index ?? -1) + 1;
}

extension IsarDateTimeValue on DateTime? {
  @pragma('vm:prefer-inline')
  int get longValue => this?.toUtc().microsecondsSinceEpoch ?? nullLong;
}
