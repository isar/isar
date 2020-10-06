import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo object) {
  var code = '''
  extension ${object.type}QueryFilter<F> on Query<${object.type}, 
    IsarCollection<${object.type}>, dynamic, QFilter, F, dynamic, dynamic> {
  ''';
  for (var property in object.properties) {
    if (property.type != DataType.Double) {
      code += generateEqualTo(object.type, property);
      code += generateNotEqualTo(object.type, property);
    }
  }
  return '''
    $code
  }''';
}

String propertyName(ObjectProperty property) {
  return property.name.decapitalize();
}

String propertyParam(ObjectProperty property) {
  return '${property.type.toTypeName()} ${property.name}';
}

String generateEqualTo(String type, ObjectProperty property) {
  return '''
  Query<$type, IsarCollection<$type>, dynamic, QFilterAfterCond, F, QCanSort, QCanExecute> 
    ${propertyName(property)}EqualTo(${propertyParam(property)}) {
    return copy();
  }
  ''';
}

String generateNotEqualTo(String type, ObjectProperty property) {
  return '''
  Query<$type, IsarCollection<$type>, dynamic, QFilterAfterCond, F, QCanSort, QCanExecute> 
    ${propertyName(property)}NotEqualTo(${propertyParam(property)}) {
    return copy();
  }
  ''';
}
