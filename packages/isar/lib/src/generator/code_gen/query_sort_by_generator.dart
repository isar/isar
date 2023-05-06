import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateSortBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QuerySortBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortBy> {''';

  for (final property in oi.properties) {
    if (property.type.isList || property.type.isObject) {
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

  extension ${oi.dartName}QuerySortThenBy on QueryBuilder<${oi.dartName}, ${oi.dartName}, QSortThenBy> {''';

  for (final property in oi.properties) {
    if (property.type.isList || property.type.isObject) {
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
