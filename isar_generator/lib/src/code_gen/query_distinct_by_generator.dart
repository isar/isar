import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct<A, B> on QueryBuilder<${oi.dartName}, 
    dynamic, dynamic, A, B, QCanSort, dynamic> {''';
  for (var index = 0; index < oi.properties.length; index++) {
    final property = oi.properties[index];
    code += '''
        QueryBuilder<${oi.dartName}, dynamic, dynamic, QCanDistinctBy, A, B,
          QCanExecute>distinctBy${property.dartName.capitalize()}() {
            return addDistinctByInternal($index);
        }''';
  }
  return '$code}';
}
