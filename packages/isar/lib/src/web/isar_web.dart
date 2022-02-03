import 'dart:js';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_native_def.dart';
import 'package:meta/meta.dart';

/// @nodoc
@protected
typedef IsarRawObject = dynamic;

/// @nodoc
@protected
typedef IsarBytePointer = dynamic;

/// @nodoc
@protected
typedef IsarBinaryReader = dynamic;

/// @nodoc
@protected
typedef IsarBinaryWriter = dynamic;

/// @nodoc
@protected
typedef IsarJsObject = JsObject;

Uint8List _isarBufAsBytes(IsarBytePointer pointer, int length) {
  throw UnimplementedError();
}

/// @nodoc
@protected
const IsarBufAsBytes isarBufAsBytes = _isarBufAsBytes;

/// @nodoc
//@protected
//const IsarSplitWords isarSplitWords = splitWords;

/// @nodoc
//@protected
//const IsarOpen isarOpen = openIsar;

Isar _isarOpenSync({
  required String directory,
  required String name,
  required bool relaxedDurability,
  required List<CollectionSchema> schemas,
}) {
  throw UnimplementedError();
}

/// @nodoc
//@protected
const IsarOpenSync isarOpenSync = _isarOpenSync;

/// @nodoc
//@protected
//const IsarCreateLink isarCreateLink = createIsarLink;

/// @nodoc
//@protected
//const IsarCreateLinks isarCreateLinks = createIsarLinks;

IsarJsObject _isarCreateJsObject() {
  return JsObject(context['Object']);
}

/// @nodoc
@protected
const IsarCreateJsObject isarCreateJsObject = _isarCreateJsObject;
