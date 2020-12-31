import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo object) {
  var code = '''
  extension ${object.type}QueryFilter<GROUPS> on QueryBuilder<${object.type}, 
    IsarCollection<${object.type}>, dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic> {
  ''';
  for (var property in object.properties) {
    if (property.type != DataType.Double) {
      code += generateEqualTo(object.type, property);
      code += generateNotEqualTo(object.type, property);
    }
    if (property.nullable) {
      code += generateIsNull(object.type, property);
      code += generateIsNotNull(object.type, property);
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

final filterReturnParams =
    'dynamic, QFilterAfterCond, GROUPS, QCanGroupBy, QCanOffsetLimit, QCanSort, QCanExecute';

String filterReturn(String type) {
  return 'QueryBuilder<$type, IsarCollection<$type>, $filterReturnParams>';
}

String generateEqualTo(String type, ObjectProperty property) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}EqualTo(${propertyParam(property)}) {
    final cloned = clone<$filterReturnParams>();
    cloned.addFilterCondition(QueryCondition(ConditionType.Eq, null, [${property.name}]));
    return cloned;
  }
  ''';
}

String generateNotEqualTo(String type, ObjectProperty property) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}NotEqualTo(${propertyParam(property)}) {
    final cloned = clone<$filterReturnParams>();
    cloned.addFilterCondition(QueryCondition(ConditionType.NEq, null, [${property.name}]));
    return cloned;
  }
  ''';
}

String generateIsNull(String type, ObjectProperty property) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}IsNull() {
    final cloned = clone<$filterReturnParams>();
    cloned.addFilterCondition(QueryCondition(ConditionType.IsNull, null, []));
    return cloned;
  }
  ''';
}

String generateIsNotNull(String type, ObjectProperty property) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}IsNotNull() {
    final cloned = clone<$filterReturnParams>();
    cloned.addFilterCondition(QueryCondition(ConditionType.IsNotNull, null, []));
    return cloned;
  }
  ''';
}
