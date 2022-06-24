import '../helper.dart';
import '../object_info.dart';

String generatePropertyQuery(ObjectInfo oi) {
  String code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, ${oi.dartName}, QQueryProperty> {''';
  for (final ObjectProperty property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, ${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addPropertyName('${property.isarName.esc}');
        });
      }''';
  }
  return '$code}';
}
