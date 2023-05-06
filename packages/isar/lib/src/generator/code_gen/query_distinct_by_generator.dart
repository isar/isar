import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

String generateDistinctBy(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryWhereDistinct on QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct> {''';
  for (final property in oi.properties.where((e) => !e.isId)) {
    if (property.type == PropertyType.string) {
      code += '''
        QueryBuilder<${oi.dartName}, ${oi.dartName}, QDistinct>distinctBy${property.dartName.capitalize()}({bool caseSensitive = true}) {
          return QueryBuilder.apply(this, (query) {
            return query.addDistinctBy(r'${property.isarName}', caseSensitive: caseSensitive);
          });
        }''';
    } else if (!property.type.isObject) {
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
