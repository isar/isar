import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';
import 'package:isar_generator/src/code_gen/util.dart';

String generateQueryFilter(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryFilter<GROUPS> on QueryBuilder<${oi.dartName}, 
  dynamic, QFilter, GROUPS, dynamic, dynamic, dynamic, dynamic> {
  ''';
  for (var i = 0; i < oi.properties.length; i++) {
    final property = oi.properties[i];
    if (!property.isFloatDouble) {
      code += generateEqualTo(oi, property, i);
      code += generateNotEqualTo(oi, property, i);
    }
    if (property.nullable) {
      code += generateIsNull(oi, property, i);
      code += generateIsNotNull(oi, property, i);
    }
    if (property.isarType != IsarType.Bool) {
      code += generateLowerThan(oi, property, i);
      code += generateGreaterThan(oi, property, i);
      code += generateBetween(oi, property, i);
    }
  }
  return '''
    $code
  }''';
}

String filterReturn(String type) {
  return 'QueryBuilder<$type, dynamic, QFilterAfterCond, GROUPS, QCanGroupBy, QCanOffsetLimit, QCanSort, QCanExecute>';
}

String generateEqualTo(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}EqualTo(${p.dartType} value) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
    ));
  }
  ''';
}

String generateNotEqualTo(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}NotEqualTo(${p.dartType} value) {
    return addFilterCondition(QueryCondition(
      ConditionType.NEq,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
    ));
  }
  ''';
}

String generateGreaterThan(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Gt,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
      includeValue: include,
    ));
  }
  ''';
}

String generateLowerThan(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}LowerThan(${p.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
      includeValue: include,
    ));
  }
  ''';
}

String generateBetween(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Between,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('lower', oi)},
      includeValue: includeLower,
      value2: ${p.toIsar('upper', oi)},
      includeValue2: includeUpper,
    ));
  }
  ''';
}

String generateIsNull(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}IsNull() {
    return addFilterCondition(QueryCondition(
      ConditionType.IsNull,
      $pIndex,
      '${p.isarType.name}',
      null,
    ));
  }
  ''';
}

String generateIsNotNull(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}IsNotNull() {
    return addFilterCondition(QueryCondition(
      ConditionType.IsNotNull,
      $pIndex,
      '${p.isarType.name}',
      null
    ));
  }
  ''';
}
