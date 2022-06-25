import 'package:dartx/dartx.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

String generateSortBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereSortBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortBy> {''';

  for (final property in oi.properties) {
    if (property.isarType.isList || property.isId) {
      continue;
    }

    code += '''
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(r'${property.isarName}', Sort.asc);
      });
    }
    
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}Desc() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(r'${property.isarName}', Sort.desc);
      });
    }''';
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhereSortThenBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortThenBy> {''';

  for (final property in oi.properties) {
    if (property.isarType.isList) {
      continue;
    }

    code += '''
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(r'${property.isarName}', Sort.asc);
      });
    }
    
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}Desc() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy(r'${property.isarName}', Sort.desc);
      });
    }''';
  }

  return '$code}';
}
