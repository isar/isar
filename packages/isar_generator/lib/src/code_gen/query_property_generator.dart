import 'package:isar_generator/src/object_info.dart';

String generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, ${oi.dartName}, QQueryProperty> {''';

  // Ids are always non-nullable regardless of their specified nullability
  code += '''
      QueryBuilder<${oi.dartName}, int, QQueryOperations>${oi.idProperty.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addPropertyName(r'${oi.idProperty.isarName}');
        });
      }''';

  for (final property in oi.objectProperties) {
    code += '''
      QueryBuilder<${oi.dartName}, ${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addPropertyName(r'${property.isarName}');
        });
      }''';
  }

  return '$code}';
}
