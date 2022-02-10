import 'package:isar_generator/src/helper.dart';
import 'package:isar_generator/src/object_info.dart';

String generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty on QueryBuilder<${oi.dartName}, ${oi.dartName}, QQueryProperty> {''';
  for (var property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, ${property.dartType}, QQueryOperations>${property.dartName}Property() {
        return addPropertyNameInternal('${property.isarName.esc}');
      }''';
  }
  return '$code}';
}
