import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo object) {
  var code = '''
  extension ${object.type}QueryFilter<GROUPS> on QueryBuilder<${object.type}, 
  dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic> {
  ''';
  for (var i = 0; i < object.properties.length; i++) {
    final property = object.properties[i];
    if (property.type != DataType.Double) {
      code += generateEqualTo(object.type, property, i);
      code += generateNotEqualTo(object.type, property, i);
    }
    if (property.nullable) {
      code += generateIsNull(object.type, property, i);
      code += generateIsNotNull(object.type, property, i);
    }
    if (property.type != DataType.Bool) {
      code += generateLowerThan(object.type, property, i);
      code += generateGreaterThan(object.type, property, i);
      code += generateBetween(object.type, property, i);
    }
  }
  return '''
    $code
  }''';
}

String propertyName(ObjectProperty property) {
  return property.name.decapitalize();
}

final filterReturnParams =
    'dynamic, QFilterAfterCond, GROUPS, QCanGroupBy, QCanOffsetLimit, QCanSort, QCanExecute';

String filterReturn(String type) {
  return 'QueryBuilder<$type, $filterReturnParams>';
}

String generateEqualTo(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}EqualTo(${property.dartType} value) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $propertyIndex,
      '${property.type.name}',
      value,
    ));
  }
  ''';
}

String generateNotEqualTo(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}NotEqualTo(${property.dartType} value) {
    return addFilterCondition(QueryCondition(
      ConditionType.NEq,
      $propertyIndex,
      '${property.type.name}',
      value,
    ));
  }
  ''';
}

String generateGreaterThan(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}GreaterThan(${property.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Gt,
      $propertyIndex,
      '${property.type.name}',
      value,
      includeValue: include,
    ));
  }
  ''';
}

String generateLowerThan(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}LowerThan(${property.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      $propertyIndex,
      '${property.type.name}',
      value,
      includeValue: include,
    ));
  }
  ''';
}

String generateBetween(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}Between(${property.dartType} lower, ${property.dartType} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Between,
      $propertyIndex,
      '${property.type.name}',
      lower,
      includeValue: includeLower,
      value2: upper,
      includeValue2: includeUpper,
    ));
  }
  ''';
}

String generateIsNull(String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}IsNull() {
    return addFilterCondition(QueryCondition(
      ConditionType.IsNull,
      $propertyIndex,
      '${property.type.name}',
      null,
    ));
  }
  ''';
}

String generateIsNotNull(
    String type, ObjectProperty property, int propertyIndex) {
  return '''
  ${filterReturn(type)} ${propertyName(property)}IsNotNull() {
    return addFilterCondition(QueryCondition(
      ConditionType.IsNotNull,
      $propertyIndex,
      '${property.type.name}',
      null
    ));
  }
  ''';
}
