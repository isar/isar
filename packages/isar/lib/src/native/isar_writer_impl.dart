// ignore_for_file: public_member_api_docs, prefer_asserts_with_message,
// avoid_positional_boolean_parameters

import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/native/encode_string.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
class IsarWriterImpl implements IsarWriter {
  IsarWriterImpl(Uint8List buffer, int staticSize)
      : _dynamicOffset = staticSize,
        _buffer = buffer,
        _byteData = ByteData.view(buffer.buffer, buffer.offsetInBytes) {
    _byteData.setUint16(0, staticSize, Endian.little);

    // Required because we don't want to persist uninitialized memory.
    for (var i = 2; i < staticSize; i++) {
      _buffer[i] = 0;
    }
  }

  final Uint8List _buffer;

  final ByteData _byteData;

  int _dynamicOffset;

  int get usedBytes => _dynamicOffset;

  @override
  @pragma('vm:prefer-inline')
  void writeBool(int offset, bool? value) {
    _buffer[offset] = value.byteValue;
  }

  @override
  @pragma('vm:prefer-inline')
  void writeByte(int offset, int value) {
    assert(value >= minByte && value <= maxByte);
    _buffer[offset] = value;
  }

  @override
  @pragma('vm:prefer-inline')
  void writeInt(int offset, int? value) {
    value ??= nullInt;
    assert(value >= minInt && value <= maxInt);
    _byteData.setInt32(offset, value, Endian.little);
  }

  @override
  @pragma('vm:prefer-inline')
  void writeFloat(int offset, double? value) {
    _byteData.setFloat32(offset, value ?? double.nan, Endian.little);
  }

  @override
  @pragma('vm:prefer-inline')
  void writeLong(int offset, int? value) {
    _byteData.setInt64(offset, value ?? nullLong, Endian.little);
  }

  @override
  @pragma('vm:prefer-inline')
  void writeDouble(int offset, double? value) {
    _byteData.setFloat64(offset, value ?? double.nan, Endian.little);
  }

  @override
  @pragma('vm:prefer-inline')
  void writeDateTime(int offset, DateTime? value) {
    writeLong(offset, value?.toUtc().microsecondsSinceEpoch);
  }

  @pragma('vm:prefer-inline')
  void _writeUint24(int offset, int value) {
    _buffer[offset] = value;
    _buffer[offset + 1] = value >> 8;
    _buffer[offset + 2] = value >> 16;
  }

  @override
  @pragma('vm:prefer-inline')
  void writeString(int offset, String? value) {
    if (value != null) {
      final byteCount = encodeString(value, _buffer, _dynamicOffset + 3);
      _writeUint24(offset, _dynamicOffset);
      _writeUint24(_dynamicOffset, byteCount);
      _dynamicOffset += byteCount + 3;
    } else {
      _writeUint24(offset, 0);
    }
  }

  @override
  @pragma('vm:prefer-inline')
  void writeObject<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    T? value,
  ) {
    if (value != null) {
      final buffer = Uint8List.sublistView(_buffer, _dynamicOffset + 3);
      final offsets = allOffsets[T]!;
      final binaryWriter = IsarWriterImpl(buffer, offsets.last);
      serialize(value, binaryWriter, offsets, allOffsets);
      final byteCount = binaryWriter.usedBytes;
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

  @override
  @pragma('vm:prefer-inline')
  void writeByteList(int offset, List<int>? values) {
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _buffer[_dynamicOffset++] = values[i];
      }
    }
  }

  @override
  void writeBoolList(int offset, List<bool?>? values) {
    _writeListOffset(offset, values?.length);

    if (values != null) {
      for (var i = 0; i < values.length; i++) {
        _buffer[_dynamicOffset++] = values[i].byteValue;
      }
    }
  }

  @override
  void writeIntList(int offset, List<int?>? values) {
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

  @override
  void writeFloatList(int offset, List<double?>? values) {
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

  @override
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

  @override
  void writeDoubleList(int offset, List<double?>? values) {
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

  @override
  void writeDateTimeList(int offset, List<DateTime?>? values) {
    final longList = values?.map((e) => e.longValue).toList();
    writeLongList(offset, longList);
  }

  @override
  void writeStringList(int offset, List<String?>? values) {
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

  @override
  void writeObjectList<T>(
    int offset,
    Map<Type, List<int>> allOffsets,
    Serialize<T> serialize,
    List<T?>? values,
  ) {
    _writeListOffset(offset, values?.length);

    if (values != null) {
      final offsetListOffset = _dynamicOffset;
      _dynamicOffset += values.length * 3;

      final offsets = allOffsets[T]!;
      final staticSize = offsets.last;
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        if (value != null) {
          final buffer = Uint8List.sublistView(_buffer, _dynamicOffset);
          final binaryWriter = IsarWriterImpl(buffer, staticSize);
          serialize(value, binaryWriter, offsets, allOffsets);
          final byteCount = binaryWriter.usedBytes;
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

extension IsarDateTimeValue on DateTime? {
  @pragma('vm:prefer-inline')
  int get longValue => this?.toUtc().microsecondsSinceEpoch ?? nullLong;
}
