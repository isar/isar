part of '../isar_generator.dart';

String _generateQueryObjects(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryObject on QueryBuilder<${oi.dartName}, '
      '${oi.dartName}, QFilterCondition> {';
  for (final property in oi.properties) {
    if (property.type != IsarType.object) {
      continue;
    }
    final name = property.dartName.decapitalize();
    code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> $name(FilterQuery<${property.typeClassName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.object(q, ${property.index});
        });
      }''';
  }

  return '''
    $code
  }''';
}
