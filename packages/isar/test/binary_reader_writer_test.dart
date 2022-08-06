@TestOn('vm')

// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:isar/src/native/binary_reader.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/version.dart';
import 'package:test/test.dart';

void main() {
  group('Golden Binary', () {
    List<Map<String, dynamic>>? json;
    late final tests = json!.map(BinaryTest.fromJson).toList();

    setUp(() async {
      final uri = Uri.parse(
        'https://raw.githubusercontent.com/isar/isar-core/'
        '$isarCoreVersion/tests/binary_golden.json',
      );
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      final completer = Completer<void>();
      final contents = StringBuffer();
      response
          .transform(utf8.decoder)
          .listen(contents.write, onDone: completer.complete);
      await completer.future;
      final jsonStr = contents.toString();
      json = (jsonDecode(jsonStr) as List).cast();
    });

    test('BinaryReader', () {
      var t = 0;
      for (final test in tests) {
        final reader = BinaryReader(Uint8List.fromList(test.bytes));
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

    test('BinaryWriter', () {
      for (final test in tests) {
        final buffer = Uint8List(10000);
        final size =
            test.types.fold<int>(0, (sum, type) => sum + type.size) + 2;

        final bufferView = buffer.buffer.asUint8List(0, test.bytes.length);
        final writer = BinaryWriter(bufferView, size);
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
  final dynamic Function(BinaryReader reader, int offset, bool nullable) read;
  final void Function(BinaryWriter reader, int offset, dynamic value) write;
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

bool? _readBool(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readBoolOrNull(offset);
  } else {
    return reader.readBool(offset);
  }
}

void _writeBool(BinaryWriter writer, int offset, dynamic value) {
  writer.writeBool(offset, value as bool?);
}

int? _readByte(BinaryReader reader, int offset, bool nullable) {
  return reader.readByte(offset);
}

void _writeByte(BinaryWriter writer, int offset, dynamic value) {
  writer.writeByte(offset, value as int);
}

int? _readInt(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readIntOrNull(offset);
  } else {
    return reader.readInt(offset);
  }
}

void _writeInt(BinaryWriter writer, int offset, dynamic value) {
  writer.writeInt(offset, value as int?);
}

double? _readFloat(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readFloatOrNull(offset);
  } else {
    return reader.readFloat(offset);
  }
}

void _writeFloat(BinaryWriter writer, int offset, dynamic value) {
  writer.writeFloat(offset, value as double?);
}

int? _readLong(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readLongOrNull(offset);
  } else {
    return reader.readLong(offset);
  }
}

void _writeLong(BinaryWriter writer, int offset, dynamic value) {
  writer.writeLong(offset, value as int?);
}

double? _readDouble(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readDoubleOrNull(offset);
  } else {
    return reader.readDouble(offset);
  }
}

void _writeDouble(BinaryWriter writer, int offset, dynamic value) {
  writer.writeDouble(offset, value as double?);
}

String? _readString(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readStringOrNull(offset);
  } else {
    return reader.readString(offset);
  }
}

void _writeString(BinaryWriter writer, int offset, dynamic value) {
  final bytes = value is String ? utf8.encode(value) as Uint8List : null;
  writer.writeByteList(offset, bytes);
}

List<bool?>? _readBoolList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readBoolOrNullList(offset);
  } else {
    return reader.readBoolList(offset);
  }
}

void _writeBoolList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeBoolList(offset, (value as List?)?.cast());
}

List<int>? _readByteList(BinaryReader reader, int offset, bool nullable) {
  return reader.readByteList(offset);
}

void _writeByteList(BinaryWriter writer, int offset, dynamic value) {
  final bytes = value is List ? Uint8List.fromList(value.cast()) : null;
  writer.writeByteList(offset, bytes);
}

List<int?>? _readIntList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readIntOrNullList(offset);
  } else {
    return reader.readIntList(offset);
  }
}

void _writeIntList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeIntList(offset, (value as List?)?.cast());
}

List<double?>? _readFloatList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readFloatOrNullList(offset);
  } else {
    return reader.readFloatList(offset);
  }
}

void _writeFloatList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeFloatList(offset, (value as List?)?.cast());
}

List<int?>? _readLongList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readLongOrNullList(offset);
  } else {
    return reader.readLongList(offset);
  }
}

void _writeLongList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeLongList(offset, (value as List?)?.cast());
}

List<double?>? _readDoubleList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readDoubleOrNullList(offset);
  } else {
    return reader.readDoubleList(offset);
  }
}

void _writeDoubleList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeDoubleList(offset, (value as List?)?.cast());
}

List<String?>? _readStringList(BinaryReader reader, int offset, bool nullable) {
  if (nullable) {
    return reader.readStringOrNullList(offset);
  } else {
    return reader.readStringList(offset);
  }
}

void _writeStringList(BinaryWriter writer, int offset, dynamic value) {
  writer.writeStringList(offset, (value as List?)?.cast());
}
