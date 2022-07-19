import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_native_interface.dart';
import 'package:isar/src/native/binary_reader.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_link_impl.dart';
import 'package:isar/src/native/open.dart';
import 'package:isar/src/native/split_words.dart';
import 'package:meta/meta.dart';

/// @nodoc
const Id isarMinId = -9223372036854775807;

/// @nodoc
const Id isarMaxId = 9223372036854775807;

/// @nodoc
const Id isarAutoIncrementId = -9223372036854775808;

/// @nodoc
@protected
typedef IsarAbi = Abi;

/// @nodoc
@protected
typedef IsarBinaryReader = BinaryReader;

/// @nodoc
@protected
typedef IsarBinaryWriter = BinaryWriter;

class _IsarNative implements IsarNativeInterface {
  const _IsarNative();

  @override
  Future<void> initializeIsarCore({
    Map<IsarAbi, String> libraries = const {},
    bool download = false,
  }) async {
    await initializeCoreBinary(
      libraries: libraries,
      download: download,
    );
  }

  @override
  T jsObjectGet<T>(Object o, Object key) {
    throw UnimplementedError();
  }

  @override
  void jsObjectSet(Object o, Object key, dynamic value) {
    throw UnimplementedError();
  }

  @override
  Object newJsObject() {
    throw UnimplementedError();
  }

  @override
  @pragma('vm:prefer-inline')
  IsarLink<OBJ> newLink<OBJ>() {
    return IsarLinkImpl();
  }

  @override
  @pragma('vm:prefer-inline')
  IsarLinks<OBJ> newLinks<OBJ>() {
    return IsarLinksImpl();
  }

  @override
  @pragma('vm:prefer-inline')
  Future<Isar> open({
    required List<CollectionSchema<dynamic>> schemas,
    String? directory,
    required String name,
    required bool relaxedDurability,
    CompactCondition? compactOnLaunch,
  }) {
    return openIsar(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Isar openSync({
    required List<CollectionSchema<dynamic>> schemas,
    String? directory,
    required String name,
    required bool relaxedDurability,
    CompactCondition? compactOnLaunch,
  }) {
    return openIsarSync(
      schemas: schemas,
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      compactOnLaunch: compactOnLaunch,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  List<String> splitWords(String value) {
    return splitWordsCore(value);
  }
}

/// @nodoc
@protected
// ignore: constant_identifier_names, library_private_types_in_public_api
const _IsarNative IsarNative = _IsarNative();
