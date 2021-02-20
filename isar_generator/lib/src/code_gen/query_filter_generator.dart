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
      if (property.nullable) {
        code += generateIsNull(oi, property, i);
      }

      if (property.isarType == IsarType.String) {
        code += generateStringEqualTo(oi, property, i);
        code += generateStringIn(oi, property, i);
        code += generateStringStartsWith(oi, property, i);
        code += generateStringEndsWith(oi, property, i);
        code += generateStringContains(oi, property, i);
        code += generateStringMatches(oi, property, i);
      } else {
        if (!property.isarType.isFloatDouble) {
          code += generateEqualTo(oi, property, i);
          if (property.isarType != IsarType.Bool) {
            code += generateIn(oi, property, i);
          }
        }

        if (property.isarType != IsarType.Bool) {
          code += generateGreaterThan(oi, property, i);
          code += generateLessThan(oi, property, i);
          code += generateBetween(oi, property, i);
        }
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
  }''';
}

String generateIn(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}In(List<${p.dartType}> values) {
    var q = beginGroup();
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${p.dartName.decapitalize()}EqualTo(values[i]).endGroup();
      } else {
        q = q.${p.dartName.decapitalize()}EqualTo(values[i]).or();
      }
    }
    throw 'Empty values is unsupported.';
  }''';
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
  }''';
}

String generateLessThan(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}LessThan(${p.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      $pIndex,
      '${p.isarType.name}',
      ${p.toIsar('value', oi)},
      includeValue: include,
    ));
  }''';
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
  }''';
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
  }''';
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
  }''';
}

String generateStringIn(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}In(List<${p.dartType}> values, {bool caseSensitive = true}) {
    var q = beginGroup();
    for (var i = 0; i < values.length; i++) {
      if (i == values.length - 1) {
        return q.${p.dartName.decapitalize()}EqualTo(values[i], caseSensitive: caseSensitive).endGroup();
      } else {
        q = q.${p.dartName.decapitalize()}EqualTo(values[i], caseSensitive: caseSensitive).or();
      }
    }
    throw 'Empty values is unsupported.';
  }''';
}

String generateStringStartsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}StartsWith(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(QueryCondition(
      ConditionType.StartsWith,
      $pIndex,
      'String',
      convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringEndsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}EndsWith(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(QueryCondition(
      ConditionType.EndsWith,
      $pIndex,
      'String',
      convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringContains(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}Contains(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(QueryCondition(
      ConditionType.Contains,
      $pIndex,
      'String',
      convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringMatches(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  ${filterReturn(oi.dartName)} ${p.dartName.decapitalize()}Matches(String pattern, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Matches,
      $pIndex,
      'String',
      pattern,
      caseSensitive: caseSensitive,
    ));
  }''';
}
