import 'package:dartx/dartx.dart';

import '../helper.dart';
import '../isar_type.dart';
import '../object_info.dart';

String generateSortBy(ObjectInfo oi) {
  String code = '''
  extension ${oi.dartName}QueryWhereSortBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortBy> {''';

  for (final ObjectProperty property in oi.properties) {
    if (property.isarType.isList || property.isId) {
      continue;
    }

    code += '''
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy('${property.isarName.esc}', Sort.asc);
      });
    }
    
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}Desc() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy('${property.isarName.esc}', Sort.desc);
      });
    }''';
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhereSortThenBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortThenBy> {''';

  for (final ObjectProperty property in oi.properties) {
    if (property.isarType.isList) {
      continue;
    }

    code += '''
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy('${property.isarName.esc}', Sort.asc);
      });
    }
    
    QueryBuilder<${oi.dartName}, ${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}Desc() {
      return QueryBuilder.apply(this, (query) {
        return query.addSortBy('${property.isarName.esc}', Sort.desc);
      });
    }''';
  }
  code += '}';

  return code;
}
