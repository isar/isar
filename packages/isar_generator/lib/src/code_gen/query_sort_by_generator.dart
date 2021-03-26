import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateSortBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereSortBy on QueryBuilder<${oi.dartName}, QSortBy> {''';

  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    if (property.isarType.isList) continue;

    /*code += '''
      QueryBuilder<${oi.dartName}, QSortThenBy>sortBy${property.dartName.capitalize()}() {
          return addDistinctByInternal($index);
      }
      
      QueryBuilder<${oi.dartName}, QSortThenBy>sortBy${property.dartName.capitalize()}Desc() {
          return addDistinctByInternal($index);
      }''';*/
  }
  code += '}';

  code += '''
  extension ${oi.dartName}QueryWhereSortThenBy on QueryBuilder<${oi.dartName}, QSortThenBy> {''';

  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    if (property.isarType.isList) continue;

    /*code += '''
      QueryBuilder<${oi.dartName}, QSortThenBy>thenBy${property.dartName.capitalize()}() {
          return addDistinctByInternal($index);
      }
      
      QueryBuilder<${oi.dartName}, QSortThenBy>thenBy${property.dartName.capitalize()}Desc() {
          return addDistinctByInternal($index);
      }''';*/
  }
  code += '}';

  return code;
}
