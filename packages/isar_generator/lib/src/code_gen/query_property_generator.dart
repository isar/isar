import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, QQueryProperty> {''';
  oi.properties.forEachIndexed((property, index) {
    code += '''
      QueryBuilder<${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return addPropertyIndex($index);
      }''';
  });
  return '$code}';
}
