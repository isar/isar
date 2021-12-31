library isar;

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:isar/src/native/isar_collection_impl.dart';
import 'package:isar/src/native/isar_impl.dart';
import 'package:isar/src/native/split_words.dart';
import 'package:meta/meta.dart';
import 'src/native/open.dart';
import 'src/native/isar_link_impl.dart';
import 'src/native/isar_type_adapter.dart';

export 'dart:ffi';
export 'dart:typed_data';
export 'package:ffi/ffi.dart';
export 'src/native/isar_type_adapter.dart';
export 'src/native/bindings.dart' show RawObject;
export 'src/native/binary/binary_reader.dart';
export 'src/native/binary/binary_writer.dart';

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

const bool kIsWeb = identical(0, 0.0);
