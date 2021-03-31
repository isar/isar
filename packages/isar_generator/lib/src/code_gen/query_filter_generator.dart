import 'package:isar_generator/src/object_info.dart';
import 'package:dartx/dartx.dart';

String generateQueryFilter(ObjectInfo oi) {
  var code =
      'extension ${oi.dartName}QueryFilter on QueryBuilder<${oi.dartName}, QFilterCondition> {';
  for (var i = 0; i < oi.properties.length; i++) {
    final property = oi.properties[i];
    if (property.isarType.isList) {
    } else {
      if (property.nullable) {
        code += generateIsNull(oi, property, i);
      }

      if (property.isarType == IsarType.String) {
        code += generateStringEqualTo(oi, property, i);
        code += generateStringStartsWith(oi, property, i);
        code += generateStringEndsWith(oi, property, i);
        code += generateStringContains(oi, property, i);
        code += generateStringMatches(oi, property, i);
      } else if (property.isarType == IsarType.Bool) {
        code += generateEqualTo(oi, property, i);
      } else {
        if (!property.isarType.isFloatDouble) {
          code += generateEqualTo(oi, property, i);
        }
        code += generateGreaterThan(oi, property, i);
        code += generateLessThan(oi, property, i);
        code += generateBetween(oi, property, i);
      }
    }
  }
  return '''
    $code
  }''';
}

String generateEqualTo(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EqualTo(${p.dartType} value) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      lower: ${p.toIsar('value', oi)},
      upper: ${p.toIsar('value', oi)},
    ));
  }''';
}

String generateGreaterThan(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}GreaterThan(${p.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Gt,
      $pIndex,
      '${p.isarType.name}',
      lower: ${p.toIsar('value', oi)},
      includeLower: include,
    ));
  }''';
}

String generateLessThan(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}LessThan(${p.dartType} value, {bool include = false}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Lt,
      $pIndex,
      '${p.isarType.name}',
      upper: ${p.toIsar('value', oi)},
      includeUpper: include,
    ));
  }''';
}

String generateBetween(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Between(${p.dartType} lower, ${p.dartType} upper, {bool includeLower = true, bool includeUpper = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Between,
      $pIndex,
      '${p.isarType.name}',
      lower: ${p.toIsar('lower', oi)},
      includeLower: includeLower,
      upper: ${p.toIsar('upper', oi)},
      includeUpper: includeUpper,
    ));
  }''';
}

String generateIsNull(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}IsNull() {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      lower: null,
      upper: null,
    ));
  }''';
}

String generateStringEqualTo(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EqualTo(${p.dartType} value, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Eq,
      $pIndex,
      '${p.isarType.name}',
      lower: ${p.toIsar('value', oi)},
      upper: ${p.toIsar('value', oi)},
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringStartsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}StartsWith(${p.dartType} value, {bool caseSensitive = true}) {
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
      lower: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringEndsWith(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}EndsWith(${p.dartType} value, {bool caseSensitive = true}) {
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
      lower: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringContains(ObjectInfo oi, ObjectProperty p, int pIndex) {
  var code = '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Contains(${p.dartType} value, {bool caseSensitive = true}) {
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
      lower: convertedValue,
      caseSensitive: caseSensitive,
    ));
  }''';
}

String generateStringMatches(ObjectInfo oi, ObjectProperty p, int pIndex) {
  return '''
  QueryBuilder<${oi.dartName}, QAfterFilterCondition> ${p.dartName.decapitalize()}Matches(String pattern, {bool caseSensitive = true}) {
    return addFilterCondition(QueryCondition(
      ConditionType.Matches,
      $pIndex,
      'String',
      lower: pattern,
      caseSensitive: caseSensitive,
    ));
  }''';
}
