import 'dart:typed_data';

import 'package:isar/isar.dart';

abstract class IsarNativeInterface {
  Uint8List bufAsBytes(IsarBytePointer pointer, int length);

  Future<void> initializeIsarCore(
      {Map<IsarAbi, String> libraries, bool download});

  List<String> splitWords(String value);

  Future<Isar> open({
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema> schemas,
  });

  Isar openSync({
    required String directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema> schemas,
  });

  IsarLink<OBJ> newLink<OBJ>();

  IsarLinks<OBJ> newLinks<OBJ>();

  dynamic newJsObject();

  dynamic jsObjectGet(Object o, Object key);

  void jsObjectSet(Object o, Object key, dynamic value);
}
