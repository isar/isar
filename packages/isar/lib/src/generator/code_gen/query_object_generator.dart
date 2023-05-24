// ignore_for_file: use_string_buffers

import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateQueryObjects(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryObject on QueryBuilder<${oi.dartName}, '
      '${oi.dartName}, QFilterCondition> {';
  for (final property in oi.properties) {
    if (!property.type.isObject) {
      continue;
    }
    var name = property.dartName.decapitalize();
    if (property.type.isList) {
      name += 'Element';
    }
    code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> $name(FilterQuery<${property.typeClassName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.object(q, r'${property.isarName}');
        });
      }''';
  }

  return '''
    $code
  }''';
}
