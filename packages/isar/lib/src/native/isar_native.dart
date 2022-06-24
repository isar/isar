import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../isar.dart';
import '../isar_native_interface.dart';
import 'binary_reader.dart';
import 'binary_writer.dart';
import 'bindings.dart';
import 'isar_core.dart';
import 'isar_link_impl.dart';
import 'open.dart';
import 'split_words.dart';

/// @nodoc
const int isarMinId = -9223372036854775807;

/// @nodoc
const int isarMaxId = 9223372036854775807;

/// @nodoc
const int isarAutoIncrementId = -9223372036854775808;

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
  T jsObjectGet<T>(Object o, Object key) {
    throw UnimplementedError();
  }

  @override
  void jsObjectSet(Object o, Object key, value) {
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
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema<dynamic>> schemas,
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
    required List<CollectionSchema<dynamic>> schemas,
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
// ignore: constant_identifier_names, library_private_types_in_public_api
const _IsarNative IsarNative = _IsarNative();
