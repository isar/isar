// ignore_for_file: use_string_buffers

part of isar_generator;

String _generateSortBy(ObjectInfo oi) {
  final prefix = 'QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>';

  var code = '''
  extension ${oi.dartName}QuerySortBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortBy> {''';

  for (final property in oi.properties) {
    if (property.type.isList || property.type.isObject) {
      continue;
    }

    final caseSensitiveParam =
        property.type.isString ? '{bool caseSensitive = true}' : '';
    final caseSensitiveArg =
        property.type.isString ? ', caseSensitive: caseSensitive,' : '';

    code += '''
    ${prefix}sortBy${property.dartName.capitalize()}($caseSensitiveParam) {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(${property.index} $caseSensitiveArg);
      });
    }
    
    ${prefix}sortBy${property.dartName.capitalize()}Desc($caseSensitiveParam) {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(${property.index}, sort: Sort.desc $caseSensitiveArg);
      });
    }''';
  }

  code += '''
  }

  extension ${oi.dartName}QuerySortThenBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortThenBy> {''';

  for (final property in oi.properties) {
    if (property.type.isList || property.type.isObject) {
      continue;
    }

    final caseSensitiveParam =
        property.type.isString ? '{bool caseSensitive = true}' : '';
    final caseSensitiveArg =
        property.type.isString ? ', caseSensitive: caseSensitive' : '';

    code += '''
    ${prefix}thenBy${property.dartName.capitalize()}($caseSensitiveParam) {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(${property.index} $caseSensitiveArg);
      });
    }
    
    ${prefix}thenBy${property.dartName.capitalize()}Desc($caseSensitiveParam) {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(${property.index}, sort: Sort.desc $caseSensitiveArg);
      });
    }''';
  }

  return '$code}';
}
