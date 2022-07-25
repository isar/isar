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
          return query.link(
            query.collection.isar.${link.targetCollectionAccessor},
            q,
            r'${link.isarName}',
          );
        });
      }''';

    if (link.links) {
      code += generateLength(oi.dartName, link.dartName,
          (lower, includeLower, upper, includeUpper) {
        return '''
        QueryBuilder.apply(this, (query) {
          return query.linkLength(
            query.collection.isar.${link.targetCollectionAccessor},
            r'${link.isarName}',
            $lower,
            $includeLower,
            $upper,
            $includeUpper,
          );
        })''';
      });
    } else {
      code += '''
      QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterFilterCondition> ${link.dartName.decapitalize()}isNull() {
        return QueryBuilder.apply(this, (query) {
          return query.linkLength(
            query.collection.isar.${link.targetCollectionAccessor},
            r'${link.isarName}',
            0,
            true,
            0,
            true,
          );
        });
      }''';
    }
  }

  return '''
    $code
  }''';
}
