import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/code_gen/query_filter_length.dart';
import 'package:isar_generator/src/object_info.dart';

String generateQueryLinks(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryLinks on QueryBuilder<${oi.dartName}, '
      '${oi.dartName}, QFilterCondition> {';
  for (final link in oi.links) {
    code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> ${link.dartName.decapitalize()}(FilterQuery<${link.targetCollectionDartName}> q) {
        return QueryBuilder.apply(this, (query) {
          return query.link(q, r'${link.isarName}');
        });
      }''';

    if (link.isSingle) {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> ${link.dartName.decapitalize()}IsNull() {
          return QueryBuilder.apply(this, (query) {
            return query.linkLength(r'${link.isarName}', 0, true, 0, true);
          });
        }''';
    } else {
      code += generateLength(oi.dartName, link.dartName,
          (lower, includeLower, upper, includeUpper) {
        return '''
        QueryBuilder.apply(this, (query) {
          return query.linkLength(r'${link.isarName}', $lower, $includeLower, $upper, $includeUpper);
        })''';
      });
    }
  }

  return '''
    $code
  }''';
}
