import 'package:dartx/dartx.dart';
import 'package:isar/isar.dart';
import 'package:isar_generator/src/code_gen/query_filter_length.dart';
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
        code += generateIsNotNull(property);
      }
      if (property.elementNullable) {
        code += generateElementIsNull(property);
        code += generateElementIsNotNull(property);
      }

      if (!property.isarType.containsObject) {
        code += generateEqualTo(property);

        if (!property.isarType.containsBool) {
          code += generateGreaterThan(property);
          code += generateLessThan(property);
          code += generateBetween(property);
        }
      }

      if (property.isarType.containsString) {
        code += generateStringStartsWith(property);
        code += generateStringEndsWith(property);
        code += generateStringContains(property);
        code += generateStringMatches(property);
        code += generateStringIsEmpty(property);
        code += generateStringIsNotEmpty(property);
      }

      if (property.isarType.isList) {
        code += generateListLength(property);
      }
    }
    return '''
    $code
  }''';
  }

  String mPrefix(ObjectProperty p, [bool listElement = true]) {
    final any = listElement && p.isarType.isList ? 'Element' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> '
        '${p.dartName.decapitalize()}$any';
  }

  String generateEqualTo(ObjectProperty p) {
    final optional = [
      if (p.isarType.containsString) 'bool caseSensitive = true',
      if (p.isarType.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}EqualTo(${p.nScalarDartType} value ${optional.isNotBlank ? ', {$optional,}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.equalTo(
          property: r'${p.isarName}',
          value: value,
          ${p.isarType.containsString ? 'caseSensitive: caseSensitive,' : ''}
          ${p.isarType.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateGreaterThan(ObjectProperty p) {
    final optional = [
      'bool include = false',
      if (p.isarType.containsString) 'bool caseSensitive = true',
      if (p.isarType.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}GreaterThan(${p.nScalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.greaterThan(
          include: include,
          property: r'${p.isarName}',
          value: value,
          ${p.isarType.containsString ? 'caseSensitive: caseSensitive,' : ''}
          ${p.isarType.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateLessThan(ObjectProperty p) {
    final optional = [
      'bool include = false',
      if (p.isarType.containsString) 'bool caseSensitive = true',
      if (p.isarType.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}LessThan(${p.nScalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.lessThan(
          include: include,
          property: r'${p.isarName}',
          value: value,
          ${p.isarType.containsString ? 'caseSensitive: caseSensitive,' : ''}
          ${p.isarType.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateBetween(ObjectProperty p) {
    final optional = [
      'bool includeLower = true',
      'bool includeUpper = true',
      if (p.isarType.containsString) 'bool caseSensitive = true',
      if (p.isarType.containsFloat) 'double epsilon = Query.epsilon',
    ].join(',');
    return '''
    ${mPrefix(p)}Between(${p.nScalarDartType} lower, ${p.nScalarDartType} upper, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.between(
          property: r'${p.isarName}',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          ${p.isarType.containsString ? 'caseSensitive: caseSensitive,' : ''}
          ${p.isarType.containsFloat ? 'epsilon: epsilon,' : ''}
        ));
      });
    }''';
  }

  String generateIsNull(ObjectProperty p) {
    return '''
      ${mPrefix(p, false)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.isNull(
            property: r'${p.isarName}',
          ));
        });
      }''';
  }

  String generateElementIsNull(ObjectProperty p) {
    return '''
      ${mPrefix(p)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.elementIsNull(
            property: r'${p.isarName}',
          ));
        });
      }''';
  }

  String generateIsNotNull(ObjectProperty p) {
    return '''
      ${mPrefix(p, false)}IsNotNull() {
        return QueryBuilder.apply(this, (query) {
          return query
            .addFilterCondition(const FilterCondition.isNotNull(
              property: r'${p.isarName}',
            ));
        });
      }''';
  }

  String generateElementIsNotNull(ObjectProperty p) {
    return '''
      ${mPrefix(p)}IsNotNull() {
        return QueryBuilder.apply(this, (query) {
          return query
            .addFilterCondition(const FilterCondition.elementIsNotNull(
              property: r'${p.isarName}',
            ));
        });
      }''';
  }

  String generateStringStartsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}StartsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.startsWith(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringEndsWith(ObjectProperty p) {
    return '''
    ${mPrefix(p)}EndsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.endsWith(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringContains(ObjectProperty p) {
    return '''
    ${mPrefix(p)}Contains(String value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.contains(
          property: r'${p.isarName}',
          value: value,
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

  String generateStringIsEmpty(ObjectProperty p) {
    return '''
    ${mPrefix(p)}IsEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.equalTo(
          property: r'${p.isarName}',
          value: '',
        ));
      });
    }''';
  }

  String generateStringIsNotEmpty(ObjectProperty p) {
    return '''
    ${mPrefix(p)}IsNotEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(FilterCondition.greaterThan(
          property: r'${p.isarName}',
          value: '',
        ));
      });
    }''';
  }

  String generateListLength(ObjectProperty p) {
    return generateLength(objName, p.dartName,
        (lower, includeLower, upper, includeUpper) {
      return '''
        QueryBuilder.apply(this, (query) {
          return query.listLength(
            r'${p.isarName}',
            $lower,
            $includeLower,
            $upper,
            $includeUpper,
          );
        })''';
    });
  }
}
