import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateSortBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereSortBy<A, B> on QueryBuilder<${oi.dartName}, 
    dynamic, dynamic, A, B, QCanSort, dynamic> {''';

  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    if (property.isarType.isList) continue;

    code += '''
        QueryBuilder<${oi.dartName}, dynamic, dynamic, A, B, QSorting,
          QCanExecute>sortBy${property.dartName.capitalize()}() {
            return addDistinctByInternal($index);
        }
        
        QueryBuilder<${oi.dartName}, dynamic, dynamic, A, B, QSorting,
          QCanExecute>sortBy${property.dartName.capitalize()}Desc() {
            return addDistinctByInternal($index);
        }''';
  }
  code += '}';

  code += '''
  extension ${oi.dartName}QueryWhereSortThenBy<A, B> on QueryBuilder<${oi.dartName}, 
    dynamic, dynamic, A, B, QSorting, dynamic> {''';

  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    if (property.isarType.isList) continue;

    code += '''
        QueryBuilder<${oi.dartName}, dynamic, dynamic, A, B, QSorting,
          QCanExecute>thenBy${property.dartName.capitalize()}() {
            return addDistinctByInternal($index);
        }
        
        QueryBuilder<${oi.dartName}, dynamic, dynamic, A, B, QSorting,
          QCanExecute>thenBy${property.dartName.capitalize()}Desc() {
            return addDistinctByInternal($index);
        }''';
  }
  code += '}';

  return code;
}
