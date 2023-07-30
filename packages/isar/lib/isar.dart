library isar;

import 'dart:async';
import 'dart:convert';

import 'package:isar/src/native/native.dart'
    if (dart.library.js) 'package:isar/src/web/web.dart';
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
part 'src/annotations/utc.dart';
part 'src/async.dart';
part 'src/compact_condition.dart';
part 'src/impl/filter_builder.dart';
part 'src/impl/isar_collection_impl.dart';
part 'src/impl/isar_impl.dart';
part 'src/impl/isar_query_impl.dart';
part 'src/impl/native_error.dart';
part 'src/isar.dart';
part 'src/isar_collection.dart';
part 'src/isar_core.dart';
part 'src/isar_error.dart';
part 'src/isar_query.dart';
part 'src/isar_schema.dart';
part 'src/query_builder.dart';
part 'src/query_components.dart';
part 'src/query_extensions.dart';

/// @nodoc
@protected
const isarProtected = protected;

/// @nodoc
@protected
const isarJsonEncode = jsonEncode;

/// @nodoc
@protected
const isarJsonDecode = jsonDecode;
