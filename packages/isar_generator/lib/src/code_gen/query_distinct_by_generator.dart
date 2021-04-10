import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, QDistinct> {''';
  for (var property in oi.properties) {
    if (property.isarType == IsarType.String) {
      code += '''
        QueryBuilder<${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}({bool caseSensitive = true}) {
            return addDistinctByInternal('${property.dartName}', caseSensitive: caseSensitive);
        }''';
    } else if (property.isarType.index < IsarType.String.index) {
      code += '''
        QueryBuilder<${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}() {
            return addDistinctByInternal('${property.dartName}');
        }''';
    }
  }
  return '$code}';
}
