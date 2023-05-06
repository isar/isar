import 'package:isar/src/generator/helper.dart';
import 'package:isar/src/generator/isar_type.dart';
import 'package:isar/src/generator/object_info.dart';

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
      if (property.nullable) {
        code += generateElementIsNull(property);
        code += generateElementIsNotNull(property);
      }

      if (!property.type.isObject) {
        code += generateEqualTo(property);

        if (!property.type.isBool) {
          code += generateGreaterThan(property);
          code += generateLessThan(property);
          code += generateBetween(property);
        }
      }

      if (property.type.isString) {
        code += generateStringStartsWith(property);
        code += generateStringEndsWith(property);
        code += generateStringContains(property);
        code += generateStringMatches(property);
        code += generateStringIsEmpty(property);
        code += generateStringIsNotEmpty(property);
      }

      if (property.type.isList) {
        //code += generateListLength(property);
      }
    }
    return '''
    $code
  }''';
  }

  String mPrefix(PropertyInfo p, [bool listElement = true]) {
    final any = listElement && p.type.isList ? 'Element' : '';
    return 'QueryBuilder<$objName, $objName, QAfterFilterCondition> '
        '${p.dartName.decapitalize()}$any';
  }

  String generateEqualTo(PropertyInfo p) {
    final optional = [
      if (p.type.isString) 'bool caseSensitive = true',
    ].join(',');
    return '''
    ${mPrefix(p)}EqualTo(${p.scalarDartType} value ${optional.isNotEmpty ? ', {$optional,}' : ''}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EqualToCondition(
          property: r'${p.isarName}',
          value: value,
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
        ));
      });
    }''';
  }

  String generateGreaterThan(PropertyInfo p) {
    final optional = [
      'bool include = false',
      if (p.type.isString) 'bool caseSensitive = true',
    ].join(',');
    return '''
    ${mPrefix(p)}GreaterThan(${p.scalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(GreaterThanCondition(
          include: include,
          property: r'${p.isarName}',
          value: value,
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
        ));
      });
    }''';
  }

  String generateLessThan(PropertyInfo p) {
    final optional = [
      'bool include = false',
      if (p.type.isString) 'bool caseSensitive = true',
    ].join(',');
    return '''
    ${mPrefix(p)}LessThan(${p.scalarDartType} value, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(LessThanCondition(
          include: include,
          property: r'${p.isarName}',
          value: value,
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
        ));
      });
    }''';
  }

  String generateBetween(PropertyInfo p) {
    final optional = [
      'bool includeLower = true',
      'bool includeUpper = true',
      if (p.type.isString) 'bool caseSensitive = true',
    ].join(',');
    return '''
    ${mPrefix(p)}Between(${p.scalarDartType} lower, ${p.scalarDartType} upper, {$optional,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(BetweenCondition(
          property: r'${p.isarName}',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          ${p.type.isString ? 'caseSensitive: caseSensitive,' : ''}
        ));
      });
    }''';
  }

  String generateIsNull(PropertyInfo p) {
    return '''
      ${mPrefix(p, false)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.isNull(
            property: r'${p.isarName}',
          ));
        });
      }''';
  }

  String generateElementIsNull(PropertyInfo p) {
    return '''
      ${mPrefix(p)}IsNull() {
        return QueryBuilder.apply(this, (query) {
          return query.addFilterCondition(const FilterCondition.elementIsNull(
            property: r'${p.isarName}',
          ));
        });
      }''';
  }

  String generateIsNotNull(PropertyInfo p) {
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

  String generateElementIsNotNull(PropertyInfo p) {
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

  String generateStringStartsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}StartsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(StartsWithCondition(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringEndsWith(PropertyInfo p) {
    return '''
    ${mPrefix(p)}EndsWith(String value, {bool caseSensitive = true,}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EndsWithCondition(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringContains(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Contains(String value, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(ContainsCondition(
          property: r'${p.isarName}',
          value: value,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringMatches(PropertyInfo p) {
    return '''
    ${mPrefix(p)}Matches(String pattern, {bool caseSensitive = true}) {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(MatchesCondition(
          property: r'${p.isarName}',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ));
      });
    }''';
  }

  String generateStringIsEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(EqualToCondition(
          property: r'${p.isarName}',
          value: '',
        ));
      });
    }''';
  }

  String generateStringIsNotEmpty(PropertyInfo p) {
    return '''
    ${mPrefix(p)}IsNotEmpty() {
      return QueryBuilder.apply(this, (query) {
        return query.addFilterCondition(GreaterThanCondition(
          property: r'${p.isarName}',
          value: '',
        ));
      });
    }''';
  }

  /*String generateListLength(PropertyInfo p) {
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
  }*/
}
