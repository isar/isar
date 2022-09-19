@TestOn('vm')

// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_reader_impl.dart';
import 'package:isar/src/native/isar_writer_impl.dart';
import 'package:test/test.dart';

void main() {
  group('Golden Binary', () {
    late final json =
        File('../isar_core/tests/binary_golden.json').readAsStringSync();
    late final tests = (jsonDecode(json) as List<dynamic>)
        .map((e) => BinaryTest.fromJson(e as Map<String, dynamic>))
        .toList();

    test('IsarReader', () {
      var t = 0;
      for (final test in tests) {
        final reader = IsarReaderImpl(Uint8List.fromList(test.bytes));
        var offset = 2;
        for (var i = 0; i < test.types.length; i++) {
          final type = test.types[i];
          final nullableValue = type.read(reader, offset, true);
          expect(nullableValue, test.values[i], reason: '${test.types} $t');

          final nonNullableValue = type.read(reader, offset, false);
          _expectIgnoreNull(nonNullableValue, test.values[i], type);
          offset += type.size;
        }
        t++;
      }
    });

    test('IsarWriter', () {
      for (final test in tests) {
        final buffer = Uint8List(10000);
        final size =
            test.types.fold<int>(0, (sum, type) => sum + type.size) + 2;

        final bufferView = buffer.buffer.asUint8List(0, test.bytes.length);
        final writer = IsarWriterImpl(bufferView, size);
        var offset = 2;
        for (var i = 0; i < test.types.length; i++) {
          final type = test.types[i];
          final value = test.values[i];
          type.write(writer, offset, value);
          offset += type.size;
        }

        expect(buffer.sublist(0, test.bytes.length), test.bytes);
      }
    });
  });
}

enum Type {
  Bool(1, false, _readBool, _writeBool),
  Byte(1, 0, _readByte, _writeByte),
  Int(4, nullInt, _readInt, _writeInt),
  Float(4, nullFloat, _readFloat, _writeFloat),
  Long(8, nullLong, _readLong, _writeLong),
  Double(8, nullDouble, _readDouble, _writeDouble),
  String(3, '', _readString, _writeString),
  BoolList(3, false, _readBoolList, _writeBoolList),
  ByteList(3, 0, _readByteList, _writeByteList),
  IntList(3, nullInt, _readIntList, _writeIntList),
  FloatList(3, nullFloat, _readFloatList, _writeFloatList),
  LongList(3, nullLong, _readLongList, _writeLongList),
  DoubleList(3, nullDouble, _readDoubleList, _writeDoubleList),
  StringList(3, '', _readStringList, _writeStringList);

  const Type(this.size, this.nullValue, this.read, this.write);

  final int size;
  final dynamic nullValue;
  final dynamic Function(IsarReader reader, int offset, bool nullable) read;
  final void Function(IsarWriter reader, int offset, dynamic value) write;
}

class BinaryTest {
  const BinaryTest(this.types, this.values, this.bytes);

  factory BinaryTest.fromJson(Map<String, dynamic> json) {
    return BinaryTest(
      (json['types'] as List)
          .map((type) => Type.values.firstWhere((t) => t.name == type))
          .toList(),
      json['values'] as List,
      (json['bytes'] as List).cast(),
    );
  }

  final List<Type> types;
  final List<dynamic> values;
  final List<int> bytes;
}

void _expectIgnoreNull(
  dynamic left,
  dynamic right,
  Type type, {
  bool inList = false,
}) {
  if (right == null && (type.index < Type.BoolList.index || inList)) {
    if (left is double) {
      expect(left, isNaN);
    } else {
      expect(left, type.nullValue);
    }
  } else if (right is List) {
    left as List;
    for (var i = 0; i < right.length; i++) {
      _expectIgnoreNull(left[i], right[i], type, inList: true);
    }
  } else {
    expect(left, right);
  }
}

bool? _readBool(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readBoolOrNull(offset);
  } else {
    return reader.readBool(offset);
  }
}

void _writeBool(IsarWriter writer, int offset, dynamic value) {
  writer.writeBool(offset, value as bool?);
}

int? _readByte(IsarReader reader, int offset, bool nullable) {
  return reader.readByte(offset);
}

void _writeByte(IsarWriter writer, int offset, dynamic value) {
  writer.writeByte(offset, value as int);
}

int? _readInt(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readIntOrNull(offset);
  } else {
    return reader.readInt(offset);
  }
}

void _writeInt(IsarWriter writer, int offset, dynamic value) {
  writer.writeInt(offset, value as int?);
}

double? _readFloat(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readFloatOrNull(offset);
  } else {
    return reader.readFloat(offset);
  }
}

void _writeFloat(IsarWriter writer, int offset, dynamic value) {
  writer.writeFloat(offset, value as double?);
}

int? _readLong(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readLongOrNull(offset);
  } else {
    return reader.readLong(offset);
  }
}

void _writeLong(IsarWriter writer, int offset, dynamic value) {
  writer.writeLong(offset, value as int?);
}

double? _readDouble(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readDoubleOrNull(offset);
  } else {
    return reader.readDouble(offset);
  }
}

void _writeDouble(IsarWriter writer, int offset, dynamic value) {
  writer.writeDouble(offset, value as double?);
}

String? _readString(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readStringOrNull(offset);
  } else {
    return reader.readString(offset);
  }
}

void _writeString(IsarWriter writer, int offset, dynamic value) {
  final bytes = value is String ? utf8.encode(value) as Uint8List : null;
  writer.writeByteList(offset, bytes);
}

List<bool?>? _readBoolList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readBoolOrNullList(offset);
  } else {
    return reader.readBoolList(offset);
  }
}

void _writeBoolList(IsarWriter writer, int offset, dynamic value) {
  writer.writeBoolList(offset, (value as List?)?.cast());
}

List<int>? _readByteList(IsarReader reader, int offset, bool nullable) {
  return reader.readByteList(offset);
}

void _writeByteList(IsarWriter writer, int offset, dynamic value) {
  final bytes = value is List ? Uint8List.fromList(value.cast()) : null;
  writer.writeByteList(offset, bytes);
}

List<int?>? _readIntList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readIntOrNullList(offset);
  } else {
    return reader.readIntList(offset);
  }
}

void _writeIntList(IsarWriter writer, int offset, dynamic value) {
  writer.writeIntList(offset, (value as List?)?.cast());
}

List<double?>? _readFloatList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readFloatOrNullList(offset);
  } else {
    return reader.readFloatList(offset);
  }
}

void _writeFloatList(IsarWriter writer, int offset, dynamic value) {
  writer.writeFloatList(offset, (value as List?)?.cast());
}

List<int?>? _readLongList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readLongOrNullList(offset);
  } else {
    return reader.readLongList(offset);
  }
}

void _writeLongList(IsarWriter writer, int offset, dynamic value) {
  writer.writeLongList(offset, (value as List?)?.cast());
}

List<double?>? _readDoubleList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readDoubleOrNullList(offset);
  } else {
    return reader.readDoubleList(offset);
  }
}

void _writeDoubleList(IsarWriter writer, int offset, dynamic value) {
  writer.writeDoubleList(offset, (value as List?)?.cast());
}

List<String?>? _readStringList(IsarReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readStringOrNullList(offset);
  } else {
    return reader.readStringList(offset);
  }
}

void _writeStringList(IsarWriter writer, int offset, dynamic value) {
  writer.writeStringList(offset, (value as List?)?.cast());
}
