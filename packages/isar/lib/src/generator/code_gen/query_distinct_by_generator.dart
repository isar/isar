part of '../isar_generator.dart';

String _generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct> {''';
  for (final property in oi.properties.where((e) => !e.isId)) {
    if (property.type == IsarType.string) {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterDistinct>distinctBy${property.dartName.capitalize()}({bool caseSensitive = true}) {
          return QueryBuilder.apply(this, (query) {
            return query.addDistinctBy(${property.index}, caseSensitive: caseSensitive);
          });
        }''';
    } else if (!property.type.isObject) {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterDistinct>distinctBy${property.dartName.capitalize()}() {
          return QueryBuilder.apply(this, (query) {
            return query.addDistinctBy(${property.index});
          });
        }''';
    }
  }
  return '$code}';
}
