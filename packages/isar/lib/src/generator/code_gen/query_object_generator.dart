// ignore_for_file: use_string_buffers

import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateQueryObjects(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryObject on QueryBuilder<${oi.dartName}, '
      '${oi.dartName}, QFilterCondition> {';
  for (final property in oi.properties) {
    if (property.type != PropertyType.object) {
      continue;
    }
    final name = property.dartName.decapitalize();
    code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> $name(FilterQuery<${property.typeClassName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.object(q, ${property.index});
        });
      }''';
  }

  return '''
    $code
  }''';
}
