import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryFilter on QueryBuilder<${oi.dartName}, QFilterCondition> {';
  for (var property in oi.properties) {
    if (property.isarType.isList) {
    } else {
      if (property.nullable) {
        code += generateIsNull(oi, property);
      }

      if (!property.isarType.isFloatDouble) {
        code += generateEqualTo(oi, property);
      }

      if (property.isarType != IsarType.Bool) {
        code += generateGreaterThan(oi, property);
        code += generateLessThan(oi, property);
        code += generateBetween(oi, property);
      }

      if (property.isarType == IsarType.String) {
        code += generateStringStartsWith(oi, property);
        code += generateStringEndsWith(oi, property);
        code += generateStringContains(oi, property);
        code += generateStringMatches(oi, property);
      }
    }
  }
  return '''
    $code
  }''';
}

String caseSensitiveProperty(ObjectProperty p) {
  if (p.isarType == IsarType.String) {
    return '{bool caseSensitive = true,}';
  } else {
    return '';
  }
}

String caseSensitiveValue(ObjectProperty p) {
  if (p.isarType == IsarType.String) {
    return 'caseSensitive: caseSensitive,';
  } else {
    return '';
  }
}

String generateEqualTo(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EqualTo(${p.dartType} value, ${caseSensitiveProperty(p)}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
      ${caseSensitiveValue(p)}
    ));
  }''';
}

String generateGreaterThan(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value, ${caseSensitiveProperty(p)}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Gt,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
      ${caseSensitiveValue(p)}
    ));
  }''';
}

String generateLessThan(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}LessThan(${p.dartType} value, ${caseSensitiveProperty(p)}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Lt,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
      ${caseSensitiveValue(p)}
    ));
  }''';
}

String generateBetween(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper, ${caseSensitiveProperty(p)}) {
    return addFilterCondition(FilterCondition.between(
      property: '${p.dartName}',
      lower: ${p.toIsar('lower', oi)},
      upper: ${p.toIsar('upper', oi)},
      ${caseSensitiveValue(p)}
    ));
  }''';
}

String generateIsNull(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}IsNull() {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: '${p.dartName}',
      value: null,
    ));
  }''';
}

String generateStringStartsWith(ObjectInfo oi, ObjectProperty p) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}StartsWith(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(FilterCondition(
      type: ConditionType.StartsWith,
      property: '${p.dartName}',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringEndsWith(ObjectInfo oi, ObjectProperty p) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EndsWith(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(FilterCondition(
      type: ConditionType.EndsWith,
      property: '${p.dartName}',
      value: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringContains(ObjectInfo oi, ObjectProperty p) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Contains(${p.dartType} value, {bool caseSensitive = true}) {
    final convertedValue = ${p.toIsar('value', oi)};''';
  if (p.nullable) {
    code += "assert(convertedValue != null, 'Null values are not allowed');";
  }
  return '''
  $code
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: '${p.dartName}',
      value: '*\$convertedValue*',
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringMatches(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Matches(String pattern, {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Matches,
      property: '${p.dartName}',
      value: pattern,
      caseSensitive: caseSensitive,
    ));
  }''';
}
