import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'isar_core.dart';

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
  bool readBool(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return false;
    }
    final int value = _buffer[offset];
    if (value == trueBool) {
      return true;
    } else {
      return false;
    }
  }

  @pragma('vm:prefer-inline')
  bool? readBoolOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return null;
    }
    final int value = _buffer[offset];
    if (value == trueBool) {
      return true;
    } else if (value == falseBool) {
      return false;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  int readInt(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return nullInt;
    }
    return _byteData.getInt32(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  int? readIntOrNull(int offset, {bool staticOffset = true}) {
    final int value = readInt(offset, staticOffset: staticOffset);
    if (value != nullInt) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  double readFloat(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return nullDouble;
    }
    return _byteData.getFloat32(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  double? readFloatOrNull(int offset, {bool staticOffset = true}) {
    final double value = readFloat(offset, staticOffset: staticOffset);
    if (!value.isNaN) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  int readLong(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return nullLong;
    }
    return _byteData.getInt64(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  int? readLongOrNull(int offset, {bool staticOffset = true}) {
    final int value = readLong(offset, staticOffset: staticOffset);
    if (value != nullLong) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  double readDouble(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return nullDouble;
    }
    return _byteData.getFloat64(offset, Endian.little);
  }

  @pragma('vm:prefer-inline')
  double? readDoubleOrNull(int offset, {bool staticOffset = true}) {
    final double value = readDouble(offset, staticOffset: staticOffset);
    if (!value.isNaN) {
      return value;
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  DateTime readDateTime(int offset, {bool staticOffset = true}) {
    final int? time = readLongOrNull(offset, staticOffset: staticOffset);
    return time != null
        ? DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal()
        : DateTime.fromMicrosecondsSinceEpoch(0);
  }

  @pragma('vm:prefer-inline')
  DateTime? readDateTimeOrNull(int offset, {bool staticOffset = true}) {
    final int? time = readLongOrNull(offset, staticOffset: staticOffset);
    if (time != null) {
      return DateTime.fromMicrosecondsSinceEpoch(time, isUtc: true).toLocal();
    } else {
      return null;
    }
  }

  @pragma('vm:prefer-inline')
  String readString(int offset, {bool staticOffset = true}) {
    return readStringOrNull(offset, staticOffset: staticOffset) ?? '';
  }

  @pragma('vm:prefer-inline')
  String? readStringOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return null;
    }
    final int bytesOffset = _byteData.getUint32(offset, Endian.little);
    if (bytesOffset == 0) {
      return null;
    }
    final int length = _byteData.getUint32(offset + 4, Endian.little);

    return utf8Decoder.convert(_buffer, bytesOffset, bytesOffset + length);
  }

  Uint8List readBytes(int offset, {bool staticOffset = true}) {
    return readBytesOrNull(offset, staticOffset: staticOffset) ??
        Uint8List.fromList([]);
  }

  Uint8List? readBytesOrNull(int offset, {bool staticOffset = true}) {
    if (staticOffset && offset >= _staticSize) {
      return null;
    }
    final int bytesOffset = _byteData.getUint32(offset, Endian.little);
    if (bytesOffset == 0) {
      return null;
    }
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    return Uint8List.view(
        _buffer.buffer, _buffer.offsetInBytes + bytesOffset, length);
  }

  List<bool>? readBoolList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<bool> list = List<bool>.filled(length, false);
    for (int i = 0; i < length; i++) {
      list[i] = readBool(listOffset + i, staticOffset: false);
    }
    return list;
  }

  List<bool?>? readBoolOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<bool?> list = List<bool?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readBoolOrNull(listOffset + i, staticOffset: false);
    }
    return list;
  }

  List<int>? readIntList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<int> list = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      list[i] = _byteData.getInt32(listOffset + i * 4, Endian.little);
    }
    return list;
  }

  List<int?>? readIntOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<int?> list = List<int?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readIntOrNull(listOffset + i * 4, staticOffset: false);
    }
    return list;
  }

  List<double>? readFloatList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<double> list = List<double>.filled(length, double.nan);
    for (int i = 0; i < length; i++) {
      list[i] = _byteData.getFloat32(listOffset + i * 4, Endian.little);
    }
    return list;
  }

  List<double?>? readFloatOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<double?> list = List<double?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readFloatOrNull(listOffset + i * 4, staticOffset: false);
    }
    return list;
  }

  List<int>? readLongList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<int> list = List<int>.filled(length, 0);
    for (int i = 0; i < length; i++) {
      list[i] = _byteData.getInt64(listOffset + i * 8, Endian.little);
    }
    return list;
  }

  List<int?>? readLongOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<int?> list = List<int?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readLongOrNull(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }

  List<double>? readDoubleList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<double> list = List<double>.filled(length, double.nan);
    for (int i = 0; i < length; i++) {
      list[i] = _byteData.getFloat64(listOffset + i * 8, Endian.little);
    }
    return list;
  }

  List<double?>? readDoubleOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<double?> list = List<double?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readDoubleOrNull(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }

  List<DateTime>? readDateTimeList(int offset) {
    return readLongOrNullList(offset)?.map((int? e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      } else {
        return nullDate;
      }
    }).toList();
  }

  List<DateTime?>? readDateTimeOrNullList(int offset) {
    return readLongOrNullList(offset)?.map((int? e) {
      if (e != null) {
        return DateTime.fromMicrosecondsSinceEpoch(e, isUtc: true).toLocal();
      }
    }).toList();
  }

  List<String>? readStringList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<String> list = List.filled(length, '');
    for (int i = 0; i < length; i++) {
      list[i] = readString(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }

  List<String?>? readStringOrNullList(int offset) {
    if (offset >= _staticSize) {
      return null;
    }

    final int listOffset = _byteData.getUint32(offset, Endian.little);
    final int length = _byteData.getUint32(offset + 4, Endian.little);
    if (listOffset == 0) {
      return null;
    }

    final List<String?> list = List<String?>.filled(length, null);
    for (int i = 0; i < length; i++) {
      list[i] = readStringOrNull(listOffset + i * 8, staticOffset: false);
    }
    return list;
  }
}
