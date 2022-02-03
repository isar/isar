import 'dart:typed_data';

import 'package:isar/isar.dart';

typedef IsarBufAsBytes = Uint8List Function(
    IsarBytePointer pointer, int length);

typedef IsarSplitWords = List<String> Function(String);

typedef IsarOpen = Future<Isar> Function({
  required String directory,
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema> schemas,
});

typedef IsarOpenSync = Isar Function({
  required String directory,
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema> schemas,
});

typedef IsarCreateLink = IsarLink<OBJ> Function<OBJ>();

typedef IsarCreateLinks = IsarLinks<OBJ> Function<OBJ>();

typedef IsarCreateJsObject = IsarJsObject Function();
