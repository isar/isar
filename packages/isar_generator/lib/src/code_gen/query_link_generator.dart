import 'package:dartx/dartx.dart';

import '../helper.dart';
import '../object_info.dart';

String generateQueryLinks(ObjectInfo oi) {
  String code =
      'extension ${oi.dartName}QueryLinks on QueryBuilder<${oi.dartName}, ${oi.dartName}, QFilterCondition> {';
  for (final ObjectLink link in oi.links) {
    code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> ${link.dartName.decapitalize()}(FilterQuery<${link.targetCollectionDartName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.link(
            query.collection.isar.${link.targetCollectionAccessor},
            q,
            '${link.isarName.esc}',
          );
        });
      }''';
  }
  return '''
    $code
  }''';
}
