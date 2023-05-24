library isar;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:isar/src/impl/bindings.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

part 'src/annotations/collection.dart';
part 'src/annotations/embedded.dart';
part 'src/annotations/enum_value.dart';
part 'src/annotations/id.dart';
part 'src/annotations/ignore.dart';
part 'src/annotations/index.dart';
part 'src/annotations/name.dart';
part 'src/annotations/type.dart';

part 'src/impl/async.dart';
part 'src/impl/filter_builder.dart';
part 'src/impl/isar_collection_impl.dart';
part 'src/impl/isar_impl.dart';
part 'src/impl/query_impl.dart';

part 'src/isar_core.dart';
part 'src/isar.dart';
part 'src/isar_collection.dart';
part 'src/isar_error.dart';
part 'src/query.dart';
part 'src/query_builder.dart';
part 'src/query_extensions.dart';
part 'src/query_components.dart';
part 'src/schema.dart';

/// @nodoc
@protected
const isarProtected = protected;

/// @nodoc
@protected
const isarJsonEncode = jsonEncode;

/// @nodoc
@protected
const isarJsonDecode = jsonDecode;
