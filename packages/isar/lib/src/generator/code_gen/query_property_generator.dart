// ignore_for_file: use_string_buffers

part of isar_generator;

String _generatePropertyQuery(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryProperty1 on QueryBuilder<${oi.dartName}, ${oi.dartName}, QProperty> {''';

  for (final property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, ${property.dartType}, QAfterProperty>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addProperty(${property.index});
        });
      }''';
  }

  code += '''
  }
  
  extension ${oi.dartName}QueryProperty2<R> on QueryBuilder<${oi.dartName}, R, QAfterProperty> {''';

  for (final property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, (R, ${property.dartType}), QAfterProperty>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addProperty(${property.index});
        });
      }''';
  }

  code += '''
  }
  
  extension ${oi.dartName}QueryProperty3<R1, R2> on QueryBuilder<${oi.dartName}, (R1, R2), QAfterProperty> {''';

  for (final property in oi.properties) {
    code += '''
      QueryBuilder<${oi.dartName}, (R1, R2, ${property.dartType}), QOperations>${property.dartName}Property() {
        return QueryBuilder.apply(this, (query) {
          return query.addProperty(${property.index});
        });
      }''';
  }

  return '$code}';
}
