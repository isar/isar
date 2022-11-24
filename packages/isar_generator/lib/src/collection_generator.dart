import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/code_gen/by_index_generator.dart';
import 'package:isar_generator/src/code_gen/collection_schema_generator.dart';
import 'package:isar_generator/src/code_gen/query_distinct_by_generator.dart';
import 'package:isar_generator/src/code_gen/query_filter_generator.dart';
import 'package:isar_generator/src/code_gen/query_link_generator.dart';
import 'package:isar_generator/src/code_gen/query_object_generator.dart';
import 'package:isar_generator/src/code_gen/query_property_generator.dart';
import 'package:isar_generator/src/code_gen/query_sort_by_generator.dart';
import 'package:isar_generator/src/code_gen/query_where_generator.dart';
import 'package:isar_generator/src/code_gen/type_adapter_generator.dart';
import 'package:isar_generator/src/isar_analyzer.dart';
import 'package:source_gen/source_gen.dart';

const ignoreLints = [
  'duplicate_ignore',
  'non_constant_identifier_names',
  'constant_identifier_names',
  'invalid_use_of_protected_member',
  'unnecessary_cast',
  'prefer_const_constructors',
  'lines_longer_than_80_chars',
  'require_trailing_commas',
  'inference_failure_on_function_invocation',
  'unnecessary_parenthesis',
  'unnecessary_raw_strings',
  'unnecessary_null_checks',
  'join_return_with_assignment',
  'prefer_final_locals',
  'avoid_js_rounded_ints',
  'avoid_positional_boolean_parameters',
  'always_specify_types',
];

class IsarCollectionGenerator extends GeneratorForAnnotation<Collection> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final object = IsarAnalyzer().analyzeCollection(element);
    return '''
      // coverage:ignore-file
      // ignore_for_file: ${ignoreLints.join(', ')}

      extension Get${object.dartName}Collection on Isar {
        IsarCollection<${object.dartName}> get ${object.accessor} => this.collection();
      }

      ${generateSchema(object)}

      ${generateEstimateSerialize(object)}
      ${generateSerialize(object)}
      ${generateDeserialize(object)}
      ${generateDeserializeProp(object)}

      ${generateEnumMaps(object)}

      ${generateGetId(object)}
      ${generateGetLinks(object)}
      ${generateAttach(object)}

      ${generateByIndexExtension(object)}
      ${WhereGenerator(object).generate()}
      ${FilterGenerator(object).generate()}
      ${generateQueryObjects(object)}
      ${generateQueryLinks(object)}
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
      // ignore_for_file: ${ignoreLints.join(', ')}

      ${generateSchema(object)}

      ${generateEstimateSerialize(object)}
      ${generateSerialize(object)}
      ${generateDeserialize(object)}
      ${generateDeserializeProp(object)}

      ${generateEnumMaps(object)}

      ${FilterGenerator(object).generate()}
      ${generateQueryObjects(object)}
    ''';
  }
}
