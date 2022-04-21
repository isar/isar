import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/code_gen/collection_schema_generator.dart';
import 'package:isar_generator/src/isar_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart';

import 'code_gen/by_index_generator.dart';
import 'code_gen/query_link_generator.dart';
import 'code_gen/type_adapter_generator_common.dart';
import 'code_gen/type_adapter_generator_native.dart';
import 'code_gen/query_distinct_by_generator.dart';
import 'code_gen/query_filter_generator.dart';
import 'code_gen/query_property_generator.dart';
import 'code_gen/query_sort_by_generator.dart';
import 'code_gen/query_where_generator.dart';
import 'code_gen/type_adapter_generator_web.dart';

class IsarCollectionGenerator extends GeneratorForAnnotation<Collection> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final object = IsarAnalyzer().analyze(element);

    var code = '''
    // ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, unused_local_variable

    extension Get${object.dartName}Collection on Isar {
      IsarCollection<${object.dartName}> get ${object.accessor} => getCollection();
    }''';

    final collectionSchema = generateCollectionSchema(object);
    final converters = object.properties
        .where((it) => it.converter != null)
        .distinctBy((it) => it.converter)
        .map((it) => 'const ${it.converterName(object)} = ${it.converter}();')
        .join('\n');

    code += '''
      $collectionSchema
      $converters

      ${generateSerializeNative(object)}
      ${generateDeserializeNative(object)}
      ${generateDeserializePropNative(object)}

      ${generateSerializeWeb(object)}
      ${generateDeserializeWeb(object)}
      ${generateDeserializePropWeb(object)}

      ${generateAttachLinks(object)}

      ${generateByIndexExtension(object)}
      ${WhereGenerator(object).generate()}
      ${FilterGenerator(object).generate()}
      ${generateQueryLinks(object)}
      ${generateSortBy(object)}
      ${generateDistinctBy(object)}
      ${generatePropertyQuery(object)}
    ''';

    return code;
  }
}
