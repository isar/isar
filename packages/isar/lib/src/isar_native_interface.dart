// ignore_for_file: public_member_api_docs

import 'package:isar/isar.dart';

abstract class IsarNativeInterface {
  Future<void> initializeIsarCore({
    Map<IsarAbi, String> libraries,
    bool download,
  });

  List<String> splitWords(String value);

  Future<Isar> open({
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema<dynamic>> schemas,
  });

  Isar openSync({
    required String directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema<dynamic>> schemas,
  });

  IsarLink<OBJ> newLink<OBJ>();

  IsarLinks<OBJ> newLinks<OBJ>();

  Object newJsObject();

  T jsObjectGet<T>(Object o, Object key);

  void jsObjectSet(Object o, Object key, dynamic value);
}
