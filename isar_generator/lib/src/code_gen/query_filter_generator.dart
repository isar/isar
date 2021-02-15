import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo oi) {
  var code = '''
  extension ${oi.dartName}QueryFilter on QueryBuilder<${oi.dartName}, 
  dynamic, QFilter, dynamic, dynamic, dynamic, dynamic> {
  ''';
  for (var i = 0; i < oi.properties.length; i++) {
    final property = oi.properties[i];
    if (property.isarType.isList) {
    } else {
      if (!property.isarType.isFloatDouble &&
          property.isarType != IsarType.String) {
        code += generateEqualTo(oi, property, i);
      }
      if (property.nullable) {
        code += generateIsNull(oi, property, i);
      }
      if (property.isarType != IsarType.Bool) {
        code += generateLowerThan(oi, property, i);
        code += generateGreaterThan(oi, property, i);
        code += generateBetween(oi, property, i);
      }
      if (property.isarType == IsarType.String) {
        code += generateStringEqualTo(oi, property, i);
        code += generateStringStartsWith(oi, property, i);
        code += generateStringEndsWith(oi, property, i);
        code += generateStringContains(oi, property, i);
      }
    }
  }
  return '''
    $code
  }''';
}

String filterReturn(String type) {
  return 'QueryBuilder<$type, dynamic, QFilterAfterCond, QCanDistinctBy, QCanOffsetLimit, QCanSort, QCanExecute>';
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
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      null,
    ));
  }
  ''';
}

String generateStringEqualTo(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}EqualTo(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
      caseSensitive: caseSensitive,
    ));
  }
  ''';
}

String generateStringStartsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}StartsWith(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.StartsWith,
      $pIndex,
      'String',
      value,
      caseSensitive: caseSensitive,
    ));
  }
  ''';
}

String generateStringEndsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}EndsWith(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.EndsWith,
      $pIndex,
      'String',
      value,
      caseSensitive: caseSensitive,
    ));
  }
  ''';
}

String generateStringContains(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}Contains(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Contains,
      $pIndex,
      'String',
      value,
      caseSensitive: caseSensitive,
    ));
  }
  ''';
}
