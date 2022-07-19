// ignore_for_file: unused_field, invalid_override, public_member_api_docs

import 'dart:js_util';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_native_interface.dart';
import 'package:isar/src/web/isar_link_impl.dart';
import 'package:isar/src/web/open.dart';
import 'package:meta/dart2js.dart';
import 'package:meta/meta.dart';

const Id isarMinId = -9007199254740991;
const Id isarMaxId = 9007199254740991;
final Id isarAutoIncrementId = double.negativeInfinity as int;

Never unsupportedOnWeb() {
  throw UnsupportedError('This operation is not supported for Isar web');
}

class _WebAbi {
  static const androidArm = null as dynamic;
  static const androidArm64 = null as dynamic;
  static const androidIA32 = null as dynamic;
  static const androidX64 = null as dynamic;
  static const iosArm64 = null as dynamic;
  static const iosX64 = null as dynamic;
  static const linuxArm64 = null as dynamic;
  static const linuxX64 = null as dynamic;
  static const macosArm64 = null as dynamic;
  static const macosX64 = null as dynamic;
  static const windowsArm64 = null as dynamic;
  static const windowsX64 = null as dynamic;
}

/// @nodoc
@protected
typedef IsarAbi = _WebAbi;

/// @nodoc
@protected
typedef IsarBinaryReader = dynamic;

/// @nodoc
@protected
// ignore: constant_identifier_names
const dynamic IsarBinaryWriter = null;

class _IsarWeb implements IsarNativeInterface {
  const _IsarWeb();

  @override
  Future<void> initializeIsarCore({
    Map<IsarAbi, String> libraries = const {},
    bool download = false,
  }) =>
      unsupportedOnWeb();

  @override
  @tryInline
  T jsObjectGet<T>(Object o, Object key) {
    return getProperty(o, key);
  }

  @override
  @tryInline
  void jsObjectSet(Object o, Object key, dynamic value) {
    setProperty(o, key, value);
  }

  @override
  @tryInline
  Object newJsObject() {
    return newObject();
  }

  @override
  @tryInline
  IsarLink<OBJ> newLink<OBJ>() {
    return IsarLinkImpl();
  }

  @override
  @tryInline
  IsarLinks<OBJ> newLinks<OBJ>() {
    return IsarLinksImpl();
  }

  @override
  @tryInline
  Future<Isar> open({
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema<dynamic>> schemas,
  }) {
    return openIsar(
      name: name,
      relaxedDurability: relaxedDurability,
      schemas: schemas,
    );
  }

  @override
  Isar openSync({
    String? directory,
    required String name,
    required bool relaxedDurability,
    required List<CollectionSchema<dynamic>> schemas,
  }) =>
      unsupportedOnWeb();

  @override
  List<String> splitWords(String value) => unsupportedOnWeb();
}

/// @nodoc
@protected
// ignore: constant_identifier_names, library_private_types_in_public_api
const _IsarWeb IsarNative = _IsarWeb();
