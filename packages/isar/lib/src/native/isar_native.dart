import 'dart:ffi';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_native_interface.dart';
import 'package:isar/src/native/binary_reader.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_link_impl.dart';
import 'package:isar/src/native/open.dart';
import 'package:meta/meta.dart';

import 'bindings.dart';
import 'split_words.dart';

/// @nodoc
const isarMinId = -9223372036854775807;

/// @nodoc
const isarMaxId = 9223372036854775807;

/// @nodoc
const isarAutoIncrementId = -9223372036854775808;

const githubUrl = 'https://github.com/isar/isar-core/releases/download';

/// @nodoc
@protected
typedef IsarAbi = Abi;

/// @nodoc
@protected
typedef IsarCObject = CObject;

/// @nodoc
@protected
typedef IsarBytePointer = Pointer<Uint8>;

/// @nodoc
@protected
typedef IsarBinaryReader = BinaryReader;

/// @nodoc
@protected
typedef IsarBinaryWriter = BinaryWriter;

class _IsarNative implements IsarNativeInterface {
  const _IsarNative();

  @override
  @pragma('vm:prefer-inline')
  Uint8List bufAsBytes(IsarBytePointer pointer, int length) {
    return pointer.asTypedList(length);
  }

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
  dynamic jsObjectGet(Object o, Object key) {
    throw UnimplementedError();
  }

  @override
  void jsObjectSet(Object o, Object key, value) {
    throw UnimplementedError();
  }

  @override
  dynamic newJsObject() {
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
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema> schemas,
  }) {
    return openIsar(
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      schemas: schemas,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  Isar openSync({
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema> schemas,
  }) {
    return openIsarSync(
      directory: directory,
      name: name,
      relaxedDurability: relaxedDurability,
      schemas: schemas,
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
// ignore: constant_identifier_names
const IsarNative = _IsarNative();
