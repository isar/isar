import 'package:dartx/dartx.dart';

import '../helper.dart';
import '../isar_type.dart';
import '../object_info.dart';

class FilterGenerator {
  FilterGenerator(this.object) : objName = object.dartName;
  final ObjectInfo object;
  final String objName;

  String generate() {
    String code =
        'extension ${objName}QueryFilter on QueryBuilder<$objName, $objName, QFilterCondition> {';
    for (final ObjectProperty property in object.properties) {
      if (property.nullable) {
        code += generateIsNull(property);
      }

      if (property.isarType != IsarType.bytes) {
        if (!property.isarType.scalarType.containsFloat) {
          code += generateEqualTo(property);
        }

        if (property.isarType.scalarType != IsarType.bool) {
          code += generateGreaterThan(property);
          code += generateLessThan(property);
          code += generateBetween(property);
        }

        if (property.isarType.scalarType == IsarType.string) {
          code += generateStringStartsWith(property);
          code += generateStringEndsWith(property);
          code += generateStringContains(property);
          code += generateStringMatches(property);
        }
      }
    }
    return '''
    $code
  }''';
  }

  String caseSensitiveProperty(ObjectProperty p) {
    if (p.isarType.containsString) {
      return 'bool caseSensitive = true,';
    } else {
      return '';
    }
  }

  String caseSensitiveValue(ObjectProperty p) {
    if (p.isarType.containsString) {
      return 'caseSensitive: caseSensitive,';
    } else {
      return '';
    }
  }

  String vType(ObjectProperty p, [bool nullable = true]) {
    if (p.isarType.isList) {
      return p.isarType.scalarType.dartType(p.nullable && nullable, false);
    } else if (nullable && !p.isId) {
      return p.dartType;
    } else {
      return p.dartType.removeSuffix('?');
    }
  }

  String mPrefix(ObjectProperty p, [bool listAny = true]) {
    final String any = listAny && p.isarType.isList ? 'Any' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> ${p.dartName.decapitalize()}$any';
  }

  String toIsar(ObjectProperty p, String name) {
    if (p.converter != null && !p.isarType.isList) {
      return p.toIsar(name, object);
    } else {
      return name;
    }
  }

  String generateEqualTo(ObjectProperty p) {
    final String optional = caseSensitiveProperty(p);
    return '''
    ${mPrefix(p)}EqualTo(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return addFilterConditionInternal(FilterCondition.equalTo(
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        ${caseSensitiveValue(p)}
      ));
    }''';
  }

  String generateGreaterThan(ObjectProperty p) {
    final String include =
        !p.isarType.containsFloat ? 'bool include = false,' : '';
    final String optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}GreaterThan(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return addFilterConditionInternal(FilterCondition.greaterThan(
        include: ${!p.isarType.containsFloat ? 'include' : 'false'},
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        ${caseSensitiveValue(p)}
      ));
    }''';
  }

  String generateLessThan(ObjectProperty p) {
    final String include =
        !p.isarType.containsFloat ? 'bool include = false,' : '';
    final String optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}LessThan(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return addFilterConditionInternal(FilterCondition.lessThan(
        include: ${!p.isarType.containsFloat ? 'include' : 'false'},
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        ${caseSensitiveValue(p)}
      ));
    }''';
  }

  String generateBetween(ObjectProperty p) {
    final String include = !p.isarType.containsFloat
        ? 'bool includeLower = true, bool includeUpper = true,'
        : '';
    final String optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}Between(${vType(p)} lower, ${vType(p)} upper ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return addFilterConditionInternal(FilterCondition.between(
        property: '${p.isarName.esc}',
        lower: ${toIsar(p, 'lower')},
        includeLower: ${!p.isarType.containsFloat ? 'includeLower' : 'false'},
        upper: ${toIsar(p, 'upper')},
        includeUpper: ${!p.isarType.containsFloat ? 'includeUpper' : 'false'},
        ${caseSensitiveValue(p)}
      ));
    }''';
  }

  String generateIsNull(ObjectProperty p) {
    String code = '''
    ${mPrefix(p, false)}IsNull() {
      return addFilterConditionInternal(const FilterCondition.isNull(
        property: '${p.isarName.esc}',
      ));
    }''';
    if (p.isarType.isList && p.isarType != IsarType.bytes) {
      code += '''
      ${mPrefix(p)}IsNull() {
        return addFilterConditionInternal(const FilterCondition.equalTo(
          property: '${p.isarName.esc}',
          value: null,
        ));
      }''';
    }
    return code;
  }

  String generateStringStartsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}StartsWith(${vType(p, false)} value, {bool caseSensitive = true,}) {
      return addFilterConditionInternal(FilterCondition.startsWith(
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        caseSensitive: caseSensitive,
      ));
    }''';
  }

  String generateStringEndsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}EndsWith(${vType(p, false)} value, {bool caseSensitive = true,}) {
      return addFilterConditionInternal(FilterCondition.endsWith(
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        caseSensitive: caseSensitive,
      ));
    }''';
  }

  String generateStringContains(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Contains(${vType(p, false)} value, {bool caseSensitive = true}) {
      return addFilterConditionInternal(FilterCondition.contains(
        property: '${p.isarName.esc}',
        value: ${toIsar(p, 'value')},
        caseSensitive: caseSensitive,
      ));
    }''';
  }

  String generateStringMatches(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return addFilterConditionInternal(FilterCondition.matches(
        property: '${p.isarName.esc}',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    }''';
  }
}
