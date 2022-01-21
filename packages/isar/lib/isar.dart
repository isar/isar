library isar;

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ffi/ffi.dart';
import 'package:meta/meta_meta.dart';

import 'src/native/isar_collection_impl.dart';
import 'src/native/isar_impl.dart';
import 'src/native/split_words.dart';
import 'src/native/bindings.dart';
import 'src/native/open.dart';
import 'src/native/isar_link_impl.dart';
import 'src/native/isar_type_adapter.dart';
import 'src/util.dart';

export 'src/native/isar_type_adapter.dart';

export 'src/native/binary_reader.dart';
export 'src/native/binary_writer.dart';

part 'package:isar/src/annotations/backlink.dart';
part 'package:isar/src/annotations/collection.dart';
part 'package:isar/src/annotations/id.dart';
part 'package:isar/src/annotations/ignore.dart';
part 'package:isar/src/annotations/index.dart';
part 'package:isar/src/annotations/name.dart';
part 'package:isar/src/annotations/size32.dart';
part 'package:isar/src/annotations/type_converter.dart';

part 'package:isar/src/isar_collection.dart';
part 'package:isar/src/collection_schema.dart';
part 'package:isar/src/isar_error.dart';
part 'package:isar/src/isar_link.dart';
part 'package:isar/src/isar.dart';
part 'package:isar/src/query_builder.dart';
part 'package:isar/src/query_builder_extensions.dart';
part 'package:isar/src/query_components.dart';
part 'package:isar/src/query.dart';

/// @nodoc
@protected
typedef IsarRawObject = RawObject;

/// @nodoc
@protected
typedef IsarUint8List = Uint8List;

/// @nodoc
@protected
Pointer<Uint8> isarMalloc(int count) => malloc(count);

/// @nodoc
@protected
void isarFree(Pointer<Uint8> pointer) => malloc.free(pointer);

/// @nodoc
@protected
Uint8List bufAsBytes(Pointer<Uint8> pointer, int length) =>
    pointer.asTypedList(length);
