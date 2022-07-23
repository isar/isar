// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

import 'package:isar/src/native/isar_core.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
class BinaryReader {
  BinaryReader(this._buffer)
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
  bool? readBoolOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readBoolOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  int readByte(int offset) {
    if (offset >= _staticSize) {
      return 0;
    }
    return _buffer[offset];
  }

  @pragma('vm:prefer-inline')
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
  int? readIntOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readIntOrNull(offset);
  }

  @pragma('vm:prefer-inline')
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
  double? readFloatOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readFloatOrNull(offset);
  }

  @pragma('vm:prefer-inline')
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
  int? readLongOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readLongOrNull(offset);
  }

  @pragma('vm:prefer-inline')
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
  double? readDoubleOrNull(int offset) {
    if (offset >= _staticSize) {
      return null;
    }
    return _readDoubleOrNull(offset);
  }

  @pragma('vm:prefer-inline')
  DateTime readDateTime(int offset) {
    final time = readLongOrNull(offset);
    return time != null
        ? DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal()
        : nullDate;
  }

  @pragma('vm:prefer-inline')
  DateTime? readDateTimeOrNull(int offset) {
    final time = readLongOrNull(offset);
    if (time != null) {
      return DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal();
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  T readEnum<T>(int offset, List<T> values) {
    final index = readByte(offset);
    if (index > 0 && index <= values.length) {
      return values[index - 1];
    } else {
      return values.first;
    }
  }

  @pragma('vm:prefer-inline')
  T? readEnumOrNull<T>(int offset, List<T> values) {
    final index = readByte(offset);
    if (index > 0 && index <= values.length) {
      return values[index - 1];
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
  String readString(int offset) {
    return readStringOrNull(offset) ?? '';
  }

  @pragma('vm:prefer-inline')
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

  Uint8List? readByteList(int offset) {
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

  List<T>? readEnumList<T>(int offset, List<T> values) {
    return readByteList(offset)?.map((index) {
      if (index > 0 && index <= values.length) {
        return values[index - 1];
      } else {
        return values.first;
      }
    }).toList();
  }

  List<T?>? readEnumOrNullList<T>(int offset, List<T> values) {
    return readByteList(offset)?.map((index) {
      if (index > 0 && index <= values.length) {
        return values[index - 1];
      } else {
        return null;
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

  List<String>? readStringList(int offset) {
    return readDynamicList(offset, '', (startOffset, endOffset) {
      return utf8Decoder.convert(_buffer, startOffset, endOffset);
    });
  }

  List<String?>? readStringOrNullList(int offset) {
    return readDynamicList(offset, null, (startOffset, endOffset) {
      return utf8Decoder.convert(_buffer, startOffset, endOffset);
    });
  }
}
