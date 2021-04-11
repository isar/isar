import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateSortBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereSortBy on QueryBuilder<${oi.dartName}, QSortBy> {''';

  for (var property in oi.properties) {
    if (property.isarType.isList) continue;

    code += '''
    QueryBuilder<${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}() {
      return addSortByInternal('${property.dartName}', Sort.Asc);
    }
    
    QueryBuilder<${oi.dartName}, QAfterSortBy>sortBy${property.dartName.capitalize()}Desc() {
      return addSortByInternal('${property.dartName}', Sort.Desc);
    }''';
  }

  code += '''
  }

  extension ${oi.dartName}QueryWhereSortThenBy on QueryBuilder<${oi.dartName}, QSortThenBy> {''';

  for (var property in oi.properties) {
    if (property.isarType.isList) continue;

    code += '''
    QueryBuilder<${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}() {
      return addSortByInternal('${property.dartName}', Sort.Asc);
    }
    
    QueryBuilder<${oi.dartName}, QAfterSortBy>thenBy${property.dartName.capitalize()}Desc() {
      return addSortByInternal('${property.dartName}', Sort.Desc);
    }''';
  }
  code += '}';

  return code;
}
