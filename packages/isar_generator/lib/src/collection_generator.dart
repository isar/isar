import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:isar_generator/src/code_gen/collection_schema_generator.dart';
import 'package:isar_generator/src/isar_analyzer.dart';
import 'package:source_gen/source_gen.dart';
import 'package:isar/isar.dart';
import 'package:dartx/dartx.dart';

import 'code_gen/by_index_generator.dart';
import 'code_gen/object_adapter_generator.dart';
import 'code_gen/query_distinct_by_generator.dart';
import 'code_gen/query_filter_generator.dart';
import 'code_gen/query_property_generator.dart';
import 'code_gen/query_sort_by_generator.dart';
import 'code_gen/query_where_generator.dart';

class IsarCollectionGenerator extends GeneratorForAnnotation<Collection> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final object = IsarAnalyzer().analyze(element);

    var code = '''
    // ignore_for_file: non_constant_identifier_names, invalid_use_of_protected_member

    extension Get${object.dartName}Collection on Isar {
      IsarCollection<${object.dartName}> get ${object.dartName.decapitalize()}s {
        return getCollection('${object.dartName}');
      }
    }''';

    final collectionSchema = generateCollectionSchema(object);
    final objectAdapter = generateObjectAdapter(object);
    final byIndexExtensions = generateByIndexExtension(object);
    final queryWhereExtensions = WhereGenerator(object).generate();
    final queryFilterExtensions = FilterGenerator(object).generate();
    final queryLinkExtensions = ''; //generateQueryLinks(object);
    final querySortByExtensions = generateSortBy(object);
    final queryDistinctByExtensions = generateDistinctBy(object);
    final propertyQueries = generatePropertyQuery(object);

    code += '''
      $collectionSchema
      $objectAdapter
      $byIndexExtensions
      $queryWhereExtensions
      $queryFilterExtensions
      $queryLinkExtensions
      $querySortByExtensions
      $queryDistinctByExtensions
      $propertyQueries''';

    return code;
  }
}
