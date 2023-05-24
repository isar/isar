import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:isar/isar.dart';
import 'package:isar/src/generator/code_gen/collection_schema_generator.dart';
import 'package:isar/src/generator/code_gen/deserialize_generator.dart';
import 'package:isar/src/generator/code_gen/enum_maps_generator.dart';
import 'package:isar/src/generator/code_gen/query_distinct_by_generator.dart';
import 'package:isar/src/generator/code_gen/query_filter_generator.dart';
import 'package:isar/src/generator/code_gen/query_property_generator.dart';
import 'package:isar/src/generator/code_gen/query_sort_by_generator.dart';
import 'package:isar/src/generator/code_gen/serialize_generator.dart';
import 'package:isar/src/generator/isar_analyzer.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:source_gen/source_gen.dart';

const _ignoreLints = [
  'duplicate_ignore',
  'invalid_use_of_protected_member',
  'lines_longer_than_80_chars',
  'constant_identifier_names',
  'avoid_js_rounded_ints',
  'no_leading_underscores_for_local_identifiers',
  'require_trailing_commas',
  'unnecessary_parenthesis',
  'unnecessary_raw_strings',
  'unnecessary_null_in_if_null_operators',
];

class IsarCollectionGenerator extends GeneratorForAnnotation<Collection> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final object = IsarAnalyzer().analyzeCollection(element);
    final idType =
        object.idProperty!.type == PropertyType.string ? 'String' : 'int';
    return '''
      // coverage:ignore-file
      // ignore_for_file: ${_ignoreLints.join(', ')}

      extension Get${object.dartName}Collection on Isar {
        IsarCollection<$idType, ${object.dartName}> get ${object.accessor} => this.collection();
      }

      ${generateSchema(object)}

      ${generateSerialize(object)}

      ${generateDeserialize(object)}

      ${generateDeserializeProp(object)}

      ${generateEnumMaps(object)}

      ${FilterGenerator(object).generate()}

      ${generateSortBy(object)}

      ${generateDistinctBy(object)}
      
      ${generatePropertyQuery(object)}
    ''';
  }
}

class IsarEmbeddedGenerator extends GeneratorForAnnotation<Embedded> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final object = IsarAnalyzer().analyzeEmbedded(element);
    return '''
      // coverage:ignore-file
      // ignore_for_file: ${_ignoreLints.join(', ')}

      ${generateSchema(object)}

      ${generateSerialize(object)}

      ${generateDeserialize(object)}

      ${generateEnumMaps(object)}
    ''';
  }
}
