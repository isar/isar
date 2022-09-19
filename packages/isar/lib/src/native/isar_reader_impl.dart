// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
class IsarReaderImpl implements IsarReader {
  IsarReaderImpl(this._buffer)
      : _byteData = ByteData.view(_buffer.buffer, _buffer.offsetInBytes) {
    _staticSize = _byteData.getUint16(0, Endian.little);
  }

  static const Utf8Decoder utf8Decoder = Utf8Decoder();

  final Uint8List _buffer;
  final ByteData _byteData;
  late int _staticSize;

  @pragma('vm:prefer-inline')
  bool _readBool(int offset) {
    final value = _buffer[offset];
    if (value == trueBool) {
      return true;
    } else {
      return false;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool readBool(int offset) {
    if (offset >= _staticSize) {
      return false;
    }
    return _readBool(offset);
  }

  @pragma('vm:prefer-inline')
  bool? _readBoolOrNull(int offset) {
    final value = _buffer[offset];
    if (value == trueBool) {
      return true;
    } else if (value == falseBool) {
      return false;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  bool? readBoolOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readBoolOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  @override
  int readByte(int offset) {
    if (offset >= _staticSize) {
      return 0;
    }
    return _buffer[offset];
  }

  @pragma('vm:prefer-inline')
  @override
  int? readByteOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _buffer[offset];
  }

  @pragma('vm:prefer-inline')
  @override
  int readInt(int offset) {
    if (offset >= _staticSize) {
      return nullInt;
    }
    return _byteData.getInt32(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  int? _readIntOrNull(int offset) {
    final value = _byteData.getInt32(offset, Endian.little);
    if (value != nullInt) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int? readIntOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readIntOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  @override
  double readFloat(int offset) {
    if (offset >= _staticSize) {
      return nullDouble;
    }
    return _byteData.getFloat32(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  double? _readFloatOrNull(int offset) {
    final value = _byteData.getFloat32(offset, Endian.little);
    if (!value.isNaN) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double? readFloatOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readFloatOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  @override
  int readLong(int offset) {
    if (offset >= _staticSize) {
      return nullLong;
    }
    return _byteData.getInt64(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  int? _readLongOrNull(int offset) {
    final value = _byteData.getInt64(offset, Endian.little);
    if (value != nullLong) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  int? readLongOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readLongOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  @override
  double readDouble(int offset) {
    if (offset >= _staticSize) {
      return nullDouble;
    }
    return _byteData.getFloat64(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  double? _readDoubleOrNull(int offset) {
    final value = _byteData.getFloat64(offset, Endian.little);
    if (!value.isNaN) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  @override
  double? readDoubleOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readDoubleOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  @override
  DateTime readDateTime(int offset) {
    final time = readLongOrNull(offset);
    return time != null
        ? DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal()
        : nullDate;
  }

  @pragma('vm:prefer-inline')
  @override
  DateTime? readDateTimeOrNull(int offset) {
    final time = readLongOrNull(offset);
    if (time != null) {
      return DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal();
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  int _readUint24(int offset) {
    return _buffer[offset] |
        _buffer[offset + 1] << 8 |
        _buffer[offset + 2] << 16;
  }

  @pragma('vm:prefer-inline')
  @override
  String readString(int offset) {
    return readStringOrNull(offset) ?? '';
  }

  @pragma('vm:prefer-inline')
  @override
  String? readStringOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var bytesOffset = _readUint24(offset);
    if (bytesOffset == 0) {
      return null;
    }

    final length = _readUint24(bytesOffset);
    bytesOffset += 3;

    return utf8Decoder.convert(_buffer, bytesOffset, bytesOffset + length);
  }

  @pragma('vm:prefer-inline')
  @override
  T? readObjectOrNull<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    if (offset >= _staticSize) {
      return null;
    }

    var bytesOffset = _readUint24(offset);
    if (bytesOffset == 0) {
      return null;
    }

    final length = _readUint24(bytesOffset);
    bytesOffset += 3;

    final buffer =
        Uint8List.sublistView(_buffer, bytesOffset, bytesOffset + length);
    final reader = IsarReaderImpl(buffer);
    final offsets = allOffsets[T]!;
    return deserialize(0, reader, offsets, allOffsets);
  }

  @override
  List<bool>? readBoolList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<bool>.filled(length, false);
    for (var i = 0; i < length; i++) {
      list[i] = _readBool(listOffset + i);
    }
    return list;
  }

  @override
  List<bool?>? readBoolOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<bool?>.filled(length, null);
    for (var i = 0; i < length; i++) {
      list[i] = _readBoolOrNull(listOffset + i);
    }
    return list;
  }

  @override
  List<int>? readByteList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    return _buffer.sublist(listOffset, listOffset + length);
  }

  @override
  List<int>? readIntList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = Int32List(length);
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getInt32(listOffset + i * 4, Endian.little);
    }
    return list;
  }

  @override
  List<int?>? readIntOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<int?>.filled(length, null);
    for (var i = 0; i < length; i++) {
      list[i] = _readIntOrNull(listOffset + i * 4);
    }
    return list;
  }

  @override
  List<double>? readFloatList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = Float32List(length);
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat32(listOffset + i * 4, Endian.little);
    }
    return list;
  }

  @override
  List<double?>? readFloatOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<double?>.filled(length, null);
    for (var i = 0; i < length; i++) {
      list[i] = _readFloatOrNull(listOffset + i * 4);
    }
    return list;
  }

  @override
  List<int>? readLongList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = Int64List(length);
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getInt64(listOffset + i * 8, Endian.little);
    }
    return list;
  }

  @override
  List<int?>? readLongOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<int?>.filled(length, null);
    for (var i = 0; i < length; i++) {
      list[i] = _readLongOrNull(listOffset + i * 8);
    }
    return list;
  }

  @override
  List<double>? readDoubleList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = Float64List(length);
    for (var i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(listOffset + i * 8, Endian.little);
    }
    return list;
  }

  @override
  List<double?>? readDoubleOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List<double?>.filled(length, null);
    for (var i = 0; i < length; i++) {
      list[i] = _readDoubleOrNull(listOffset + i * 8);
    }
    return list;
  }

  @override
  List<DateTime>? readDateTimeList(int offset) {
    return readLongOrNullList(offset)?.map((e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      } else {
        return nullDate;
      }
    }).toList();
  }

  @override
  List<DateTime?>? readDateTimeOrNullList(int offset) {
    return readLongOrNullList(offset)?.map((e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      }
    }).toList();
  }

  List<T>? readDynamicList<T>(
    int offset,
    T nullValue,
    T Function(int startOffset, int endOffset) transform,
  ) {
    if (offset >= _staticSize) {
      return null;
    }

    var listOffset = _readUint24(offset);
    if (listOffset == 0) {
      return null;
    }

    final length = _readUint24(listOffset);
    listOffset += 3;

    final list = List.filled(length, nullValue);
    var contentOffset = listOffset + length * 3;
    for (var i = 0; i < length; i++) {
      final itemSize = _readUint24(listOffset + i * 3);

      if (itemSize != 0) {
        list[i] = transform(contentOffset, contentOffset + itemSize - 1);
        contentOffset += itemSize - 1;
      }
    }

    return list;
  }

  @override
  List<String>? readStringList(int offset) {
    return readDynamicList(offset, '', (startOffset, endOffset) {
      return utf8Decoder.convert(_buffer, startOffset, endOffset);
    });
  }

  @override
  List<String?>? readStringOrNullList(int offset) {
    return readDynamicList(offset, null, (startOffset, endOffset) {
      return utf8Decoder.convert(_buffer, startOffset, endOffset);
    });
  }

  @override
  List<T>? readObjectList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
    T defaultValue,
  ) {
    final offsets = allOffsets[T]!;
    return readDynamicList(offset, defaultValue, (startOffset, endOffset) {
      final buffer = Uint8List.sublistView(_buffer, startOffset, endOffset);
      final reader = IsarReaderImpl(buffer);
      return deserialize(0, reader, offsets, allOffsets);
    });
  }

  @override
  List<T?>? readObjectOrNullList<T>(
    int offset,
    Deserialize<T> deserialize,
    Map<Type, List<int>> allOffsets,
  ) {
    final offsets = allOffsets[T]!;
    return readDynamicList(offset, null, (startOffset, endOffset) {
      final buffer = Uint8List.sublistView(_buffer, startOffset, endOffset);
      final reader = IsarReaderImpl(buffer);
      return deserialize(0, reader, offsets, allOffsets);
    });
  }
}
