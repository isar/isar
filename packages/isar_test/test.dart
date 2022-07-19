import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:ffi/ffi.dart';

@Collection()
class StringModel {
  StringModel();

  StringModel.init(String? value)
      : field = value,
        hashField = value;
  Id? id;

  @Index(type: IndexType.value)
  String? field = '';

  @Index(type: IndexType.hash)
  String? hashField = '';

  @Index(type: IndexType.value)
  List<String>? list;

  @Index(type: IndexType.hash)
  List<String>? hashList;

  @Index(type: IndexType.hashElements)
  List<String>? hashElementList;

  @override
  String toString() {
    return '{field: $field, hashField: $hashField, list: $list, hashList: '
        '$hashList, hashElementList: $hashElementList}';
  }
}

void _stringModelSerializeNative(StringModel object, int staticSize,
    List<int> offsets, Uint8List Function(int) alloc) {
  IsarUint8List? field$Bytes;
  final field$Value = object.field;
  if (field$Value != null) {
    field$Bytes = IsarBinaryWriter.utf8Encoder.convert(field$Value);
  }
  List<IsarUint8List?>? hashElementList$BytesList;
  var hashElementList$BytesCount = 0;
  final hashElementList$Value = object.hashElementList;
  if (hashElementList$Value != null) {
    hashElementList$BytesCount = 3 + hashElementList$Value.length * 3;
    hashElementList$BytesList = [];
    for (final str in hashElementList$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      hashElementList$BytesList.add(bytes);
      hashElementList$BytesCount += bytes.length as int;
    }
  }
  IsarUint8List? hashField$Bytes;
  final hashField$Value = object.hashField;
  if (hashField$Value != null) {
    hashField$Bytes = IsarBinaryWriter.utf8Encoder.convert(hashField$Value);
  }
  List<IsarUint8List?>? hashList$BytesList;
  var hashList$BytesCount = 0;
  final hashList$Value = object.hashList;
  if (hashList$Value != null) {
    hashList$BytesCount = 3 + hashList$Value.length * 3;
    hashList$BytesList = [];
    for (final str in hashList$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      hashList$BytesList.add(bytes);
      hashList$BytesCount += bytes.length as int;
    }
  }
  List<IsarUint8List?>? list$BytesList;
  var list$BytesCount = 0;
  final list$Value = object.list;
  if (list$Value != null) {
    list$BytesCount = 3 + list$Value.length * 3;
    list$BytesList = [];
    for (final str in list$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      list$BytesList.add(bytes);
      list$BytesCount += bytes.length as int;
    }
  }
  final size = (staticSize +
      (field$Bytes != null ? 3 + field$Bytes.length : 0) +
      hashElementList$BytesCount +
      (hashField$Bytes != null ? 3 + hashField$Bytes.length : 0) +
      hashList$BytesCount +
      list$BytesCount) as int;

  final writer = IsarBinaryWriter(alloc(size), staticSize);
  writer.writeHeader();
  writer.writeByteList(offsets[0], field$Bytes);
  writer.writeByteLists(offsets[1], hashElementList$BytesList);
  writer.writeByteList(offsets[2], hashField$Bytes);
  writer.writeByteLists(offsets[3], hashList$BytesList);
  writer.writeByteLists(offsets[4], list$BytesList);
  writer.validate();
}

int prepareSerialize(StringModel object, List<dynamic> values) {
  var bytesCount = 0;

  final field$Value = object.field;
  if (field$Value != null) {
    final bytes = IsarBinaryWriter.utf8Encoder.convert(field$Value);
    bytesCount += bytes.length;
    values.add(bytes);
  }

  List<IsarUint8List?>? hashElementList$BytesList;
  final hashElementList$Value = object.hashElementList;
  if (hashElementList$Value != null) {
    bytesCount += 3 + hashElementList$Value.length * 3;
    hashElementList$BytesList = [];
    for (final str in hashElementList$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      hashElementList$BytesList.add(bytes);
      bytesCount += bytes.length;
    }
  }
  values.add(hashElementList$BytesList);

  IsarUint8List? hashField$Bytes;
  final hashField$Value = object.hashField;
  if (hashField$Value != null) {
    hashField$Bytes = IsarBinaryWriter.utf8Encoder.convert(hashField$Value);
    bytesCount += hashField$Bytes.length;
  }
  values.add(hashField$Bytes);

  List<IsarUint8List?>? hashList$BytesList;
  final hashList$Value = object.hashList;
  if (hashList$Value != null) {
    bytesCount += 3 + hashList$Value.length * 3;
    hashList$BytesList = [];
    for (final str in hashList$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      hashList$BytesList.add(bytes);
      bytesCount += bytes.length as int;
    }
  }
  values.add(hashList$BytesList);

  List<IsarUint8List?>? list$BytesList;
  final list$Value = object.list;
  if (list$Value != null) {
    bytesCount += 3 + list$Value.length * 3;
    list$BytesList = [];
    for (final str in list$Value) {
      final bytes = IsarBinaryWriter.utf8Encoder.convert(str);
      list$BytesList.add(bytes);
      bytesCount += bytes.length as int;
    }
  }
  values.add(list$BytesList);

  return bytesCount;
}

void _stringModelSerializeNative2(StringModel object, int staticSize,
    List<int> offsets, Uint8List Function(int) alloc) {
  final values = <dynamic>[];

  final size = staticSize + prepareSerialize(object, values);

  final writer = IsarBinaryWriter(alloc(size), staticSize);
  writer.writeHeader();
  var i = 0;
  writer.writeByteList(offsets[0], values[i++] as List<int>?);
  writer.writeByteLists(offsets[1], values[i++] as List<Uint8List?>?);
  writer.writeByteList(offsets[2], values[i++] as List<int>?);
  writer.writeByteLists(offsets[3], values[i++] as List<Uint8List?>?);
  writer.writeByteLists(offsets[4], values[i++] as List<Uint8List?>?);
  writer.validate();
}

void main() {
  final model = StringModel()
    ..field = 'this is just a string'
    ..hashElementList = [
      for (var i = 0; i < 10; i++) 'this isasdf st a string',
    ]
    ..hashField = 'jdsafahsd fasdflij asdflaisjdf '
    ..hashList = [
      for (var i = 0; i < 15; i++) 'this isasd asg',
    ]
    ..list = ['a', 'b', 'c'];

  final buffer = Uint8List(100000);
  final a = Arena();
  for (var i = 0; i < 10; i++) {
    final s1 = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      a.allocate(100);
      a.allocate(100);
      a.allocate(100);
      a.allocate(100);
      a.allocate(100);

      /*_stringModelSerializeNative2(
        model,
        100,
        [10, 20, 30, 40, 50, 60],
        (size) => buffer,
      );*/
    }
    s1.stop();

    final s2 = Stopwatch()..start();
    for (var i = 0; i < 1000; i++) {
      /*_stringModelSerializeNative(
        model,
        100,
        [10, 20, 30, 40, 50, 60],
        (size) => buffer,
      );*/
      a.allocate(500);
    }

    s2.stop();

    print('s1: ${s1.elapsedMicroseconds} s2: ${s2.elapsedMicroseconds}');
  }
}
