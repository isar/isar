library isar;

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

part 'src/annotations/collection.dart';
part 'src/annotations/embedded.dart';
part 'src/annotations/enumerated.dart';
part 'src/annotations/id.dart';
part 'src/annotations/ignore.dart';
part 'src/annotations/index.dart';
part 'src/annotations/name.dart';
part 'src/annotations/type.dart';
part 'src/isar.dart';
part 'src/isar_collection.dart';
part 'src/isar_error.dart';
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
