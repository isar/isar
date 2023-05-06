import 'package:isar/src/generator/object_info.dart';

String generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, ${oi.dartName}, QQueryProperty> {''';

  for (final property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, ${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addPropertyName(r'${property.isarName}');
        });
      }''';
  }

  return '$code}';
}
