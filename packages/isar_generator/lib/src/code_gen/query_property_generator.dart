import 'package:isar_generator/src/object_info.dart';

String generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, QQueryProperty> {''';
  for (var property in oi.properties) {
    code += '''
      QueryBuilder<${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return addPropertyName('${property.dartName}');
      }''';
  }
  return '$code}';
}
