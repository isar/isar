import 'package:dartx/dartx.dart';

import 'package:isar_generator/src/isar_type.dart';
import 'package:isar_generator/src/object_info.dart';

class FilterGenerator {
  FilterGenerator(this.object) : objName = object.dartName;
  final ObjectInfo object;
  final String objName;

  String generate() {
    var code =
        'extension ${objName}QueryFilter on QueryBuilder<$objName, $objName, '
        'QFilterCondition> {';
    for (final property in object.properties) {
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
    final any = listAny && p.isarType.isList ? 'Element' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> '
        '${p.dartName.decapitalize()}$any';
  }

  String toIsar(ObjectProperty p, String name) {
    if (p.converter != null && !p.isarType.isList) {
      return p.toIsar(name, object);
    } else {
      return name;
    }
  }

  String generateEqualTo(ObjectProperty p) {
    final optional = caseSensitiveProperty(p);
    return '''
    ${mPrefix(p)}EqualTo(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.equalTo(
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateGreaterThan(ObjectProperty p) {
    final include = !p.isarType.containsFloat ? 'bool include = false,' : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}GreaterThan(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.greaterThan(
          ${!p.isarType.containsFloat ? 'include: include,' : ''}
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateLessThan(ObjectProperty p) {
    final include = !p.isarType.containsFloat ? 'bool include = false,' : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}LessThan(${vType(p)} value ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.lessThan(
          ${!p.isarType.containsFloat ? 'include: include,' : ''}
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateBetween(ObjectProperty p) {
    final include = !p.isarType.containsFloat
        ? 'bool includeLower = true, bool includeUpper = true,'
        : '';
    final optional = '${caseSensitiveProperty(p)} $include';
    return '''
    ${mPrefix(p)}Between(${vType(p)} lower, ${vType(p)} upper ${optional.isNotBlank ? ', {$optional}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.between(
          property: r'${p.isarName}',
          lower: ${toIsar(p, 'lower')},
          includeLower: ${!p.isarType.containsFloat ? 'includeLower' : 'false'},
          upper: ${toIsar(p, 'upper')},
          includeUpper: ${!p.isarType.containsFloat ? 'includeUpper' : 'false'},
          ${caseSensitiveValue(p)}
        ));
      });
    }''';
  }

  String generateIsNull(ObjectProperty p) {
    var code = '''
    ${mPrefix(p, false)}IsNull() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(const FilterCondition.isNull(
          property: r'${p.isarName}',
        ));
      });
    }''';
    if (p.isarType.isList && p.isarType != IsarType.bytes) {
      code += '''
      ${mPrefix(p)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.equalTo(
            property: r'${p.isarName}',
            value: null,
          ));
        });
      }''';
    }
    return code;
  }

  String generateStringStartsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}StartsWith(${vType(p, false)} value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.startsWith(
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringEndsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}EndsWith(${vType(p, false)} value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.endsWith(
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringContains(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Contains(${vType(p, false)} value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.contains(
          property: r'${p.isarName}',
          value: ${toIsar(p, 'value')},
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringMatches(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.matches(
          property: r'${p.isarName}',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }
}
