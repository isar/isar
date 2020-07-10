import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo object) {
  var code = '''
  extension ${object.type}QueryFilter on QueryBuilder<${object.type}, 
    IsarBank<${object.type}>, dynamic, FilterT, dynamic, dynamic> {
  ''';
  for (var field in object.fields) {
    if (field.type != DataType.Double) {
      code += generateEqualTo(object.type, field);
      code += generateNotEqualTo(object.type, field);
    }
  }
  return '''
    $code
  }''';
}

String fieldName(ObjectField field) {
  return field.name.decapitalize();
}

String fieldParam(ObjectField field) {
  return '${field.type.toTypeName()} ${field.name}';
}

String generateEqualTo(String type, ObjectField field) {
  return '''
  QueryBuilder<$type, IsarBank<$type>, dynamic, FilterAndOrT, CanSort, CanExecute> 
    ${fieldName(field)}EqualTo(${fieldParam(field)}) {
    return QueryBuilder();
  }
  ''';
}

String generateNotEqualTo(String type, ObjectField field) {
  return '''
  QueryBuilder<$type, IsarBank<$type>, dynamic, FilterAndOrT, CanSort, CanExecute> 
    ${fieldName(field)}NotEqualTo(${fieldParam(field)}) {
    return QueryBuilder();
  }
  ''';
}
