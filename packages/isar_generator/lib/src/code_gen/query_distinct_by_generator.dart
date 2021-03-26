import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, QDistinct> {''';
  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    code += '''
        QueryBuilder<${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}() {
            return addDistinctByInternal($index);
        }''';
  }
  return '$code}';
}
