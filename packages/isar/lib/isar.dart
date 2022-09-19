library isar;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:isar/src/isar_connect_api.dart';
import 'package:isar/src/native/isar_core.dart'
    if (dart.library.html) 'package:isar/src/web/isar_web.dart';
import 'package:isar/src/native/isar_link_impl.dart'
    if (dart.library.html) 'package:isar/src/web/isar_link_impl.dart';
import 'package:isar/src/native/open.dart'
    if (dart.library.html) 'package:isar/src/web/open.dart';
import 'package:isar/src/native/split_words.dart'
    if (dart.library.html) 'package:isar/src/web/split_words.dart';
import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

part 'src/annotations/backlink.dart';
part 'src/annotations/collection.dart';
part 'src/annotations/embedded.dart';
part 'src/annotations/enumerated.dart';
part 'src/annotations/ignore.dart';
part 'src/annotations/index.dart';
part 'src/annotations/name.dart';
part 'src/annotations/type.dart';
part 'src/isar.dart';
part 'src/isar_collection.dart';
part 'src/isar_connect.dart';
part 'src/isar_error.dart';
part 'src/isar_link.dart';
part 'src/isar_reader.dart';
part 'src/isar_writer.dart';
part 'src/query.dart';
part 'src/query_builder.dart';
part 'src/query_builder_extensions.dart';
part 'src/query_components.dart';
part 'src/schema/collection_schema.dart';
part 'src/schema/index_schema.dart';
part 'src/schema/link_schema.dart';
part 'src/schema/property_schema.dart';
part 'src/schema/schema.dart';

/// @nodoc
@protected
typedef IsarUint8List = Uint8List;

const bool _kIsWeb = identical(0, 0.0);
