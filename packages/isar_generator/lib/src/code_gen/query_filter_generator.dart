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

      if (property.isarType == IsarType.String) {
        code += generateStringEqualTo(oi, property);
        code += generateStringStartsWith(oi, property);
        code += generateStringEndsWith(oi, property);
        code += generateStringContains(oi, property);
        code += generateStringMatches(oi, property);
      } else if (property.isarType == IsarType.Bool) {
        code += generateEqualTo(oi, property);
      } else {
        if (!property.isarType.isFloatDouble) {
          code += generateEqualTo(oi, property);
        }
        code += generateGreaterThan(oi, property);
        code += generateLessThan(oi, property);
        code += generateBetween(oi, property);
      }
    }
  }
  return '''
    $code
  }''';
}

String generateEqualTo(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EqualTo(${p.dartType} value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
    ));
  }''';
}

String generateGreaterThan(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Gt,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
    ));
  }''';
}

String generateLessThan(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}LessThan(${p.dartType} value) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Lt,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
    ));
  }''';
}

String generateBetween(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper) {
    return addFilterCondition(FilterCondition.between(
      property: '${p.dartName}',
      lower: ${p.toIsar('lower', oi)},
      upper: ${p.toIsar('upper', oi)},
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

String generateStringEqualTo(ObjectInfo oi, ObjectProperty p) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EqualTo(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(FilterCondition(
      type: ConditionType.Eq,
      property: '${p.dartName}',
      value: ${p.toIsar('value', oi)},
      caseSensitive: caseSensitive,
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
