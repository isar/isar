import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo object) {
  var code = """
  extension ${object.name}QueryFilter on QueryBuilder<${object.name}, 
    IsarBank<${object.name}>, dynamic, FilterT, dynamic, dynamic> {
  """;
  for (var field in object.fields) {
    if (field.type != DataType.Double) {
      code += generateEqualTo(object.name, field);
      code += generateNotEqualTo(object.name, field);
    }
  }
  return """
    $code
  }""";
}

String fieldName(ObjectField field) {
  return field.name.decapitalize();
}

String fieldParam(ObjectField field) {
  return "${field.type.toTypeName()} ${field.name}";
}

String generateEqualTo(String type, ObjectField field) {
  return """
  QueryBuilder<$type, IsarBank<$type>, dynamic, FilterAndOrT, CanSort, CanExecute> 
    ${fieldName(field)}EqualTo(${fieldParam(field)}) {
    return QueryBuilder();
  }
  """;
}

String generateNotEqualTo(String type, ObjectField field) {
  return """
  QueryBuilder<$type, IsarBank<$type>, dynamic, FilterAndOrT, CanSort, CanExecute> 
    ${fieldName(field)}NotEqualTo(${fieldParam(field)}) {
    return QueryBuilder();
  }
  """;
}
