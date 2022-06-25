import 'package:dartx/dartx.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct> {''';
  for (final property in oi.properties) {
    if (property.isId) {
      continue;
    }

    if (property.isarType == IsarType.string) {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}({bool caseSensitive = true}) {
          return QueryBuilder.apply(this, (query) {
            return query.addDistinctBy(r'${property.isarName}', caseSensitive: caseSensitive);
          });
        }''';
    } else {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}() {
          return QueryBuilder.apply(this, (query) {
            return query.addDistinctBy(r'${property.isarName}');
          });
        }''';
    }
  }
  return '$code}';
}
