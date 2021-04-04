import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, QDistinct> {''';
  final properties =
      oi.properties.where((p) => p.isarType.index <= IsarType.String.index);
  properties.forEachIndexed((property, index) {
    if (property.isarType == IsarType.String) {
      code += '''
        QueryBuilder<${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}({bool caseSensitive = true}) {
            return addDistinctByInternal($index, caseSensitive: caseSensitive);
        }''';
    } else {
      code += '''
        QueryBuilder<${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}() {
            return addDistinctByInternal($index);
        }''';
    }
  });
  return '$code}';
}
