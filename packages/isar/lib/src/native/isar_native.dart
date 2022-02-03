import 'dart:ffi';

import 'package:isar/isar.dart';
import 'package:isar/src/isar_native_def.dart';
import 'package:isar/src/native/binary_reader.dart';
import 'package:isar/src/native/binary_writer.dart';
import 'package:isar/src/native/isar_core.dart';
import 'package:isar/src/native/isar_link_impl.dart';
import 'package:isar/src/native/open.dart';
import 'package:meta/meta.dart';

import 'bindings.dart';
import 'split_words.dart';

/// @nodoc
@protected
typedef IsarRawObject = RawObject;

/// @nodoc
@protected
typedef IsarBytePointer = Pointer<Uint8>;

/// @nodoc
@protected
typedef IsarBinaryReader = BinaryReader;

/// @nodoc
@protected
typedef IsarBinaryWriter = BinaryWriter;

/// @nodoc
@protected
typedef IsarJsObject = dynamic;

/// @nodoc
@protected
const IsarBufAsBytes isarBufAsBytes = bufAsBytes;

/// @nodoc
@protected
const IsarSplitWords isarSplitWords = splitWords;

/// @nodoc
@protected
const IsarOpen isarOpen = openIsar;

/// @nodoc
@protected
const IsarOpenSync isarOpenSync = openIsarSync;

/// @nodoc
@protected
const IsarCreateLink isarCreateLink = createIsarLink;

/// @nodoc
@protected
const IsarCreateLinks isarCreateLinks = createIsarLinks;

IsarJsObject _isarCreateJsObject() {
  throw UnimplementedError();
}

/// @nodoc
@protected
const IsarCreateJsObject isarCreateJsObject = _isarCreateJsObject;
